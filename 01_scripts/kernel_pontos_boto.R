# Carrega os pacotes necessários
source("01_scripts/calcular_limiar.R")

library(sf)
library(spatstat)
library(terra)

library(spatialEco)

# --- Parte 1: Preparando a camada de água ---

pasta_proj <- rprojroot::find_rstudio_root_file()
agua_sf <- st_read(file.path(pasta_proj, "00_data", "amostragem_area.gpkg"), layer = "agua")
agua_proj <- st_transform(agua_sf, 32723)
agua_owin <- as.owin(agua_proj)

# --- Parte 2: Preparando os pontos dos grupos ---

grupos_sf <- st_read(file.path(pasta_proj, "00_data", "amostragem_rotas_pratica_2022-12-01_2025-12-02.gpkg"), layer = "pontos")
grupos_proj <- st_transform(grupos_sf, 32723)
grupos_ppp <- as.ppp(grupos_proj)
marks(grupos_ppp) <- as.data.frame(grupos_sf)[, -which(names(grupos_sf) == "geom")]
Window(grupos_ppp) <- agua_owin
unitname(grupos_ppp) <- c("metro", "metros")

# --- Parte 3: Análise de Kernel Density ---

grupos_ppp <- rescale.ppp(grupos_ppp, 1000, "km")
grupos_ppp <- unique.ppp(grupos_ppp)
kernel <- density.ppp(grupos_ppp,
                      kernel = "gaussian",
                      sigma = bw.ppl(grupos_ppp),
                      edge = TRUE,
                      diggle = TRUE,
                      positive = TRUE,
                      weights = grupos_ppp$marks$tam_est)
kernel <- rescale.im(kernel, .001, unitname = c("metro", "metros"))
rast_proj <- rast(kernel)
crs(rast_proj) <- "epsg:32723"

# --- Parte 4: Extração de polígonos de densidade ---

limiar_95 <- calcular_limiar(rast_proj, 0.95)  # Área que contém 95% da densidade
limiar_50 <- calcular_limiar(rast_proj, 0.50)  # Área que contém 50% da densidade
mascara_95 <- rast_proj >= limiar_95
mascara_50 <- rast_proj >= limiar_50
p95 <- as.polygons(mascara_95, dissolve = TRUE) %>% simplifyGeom(tolerance = 10)
p50 <- as.polygons(mascara_50, dissolve = TRUE) %>% simplifyGeom(tolerance = 10)

# --- Parte 5: Exportação dos Resultados (em GPKG) ---

novo_dir <- file.path(pasta_proj, "02_results")
dir.create(novo_dir, recursive = TRUE, showWarnings = FALSE)
writeRaster(rast_proj,
            filename = file.path(novo_dir, "kernel.tif"),
            overwrite = TRUE)
p50_sf <- st_as_sf(p50)[2,]
p95_sf <- st_as_sf(p95)[2,]
st_write(p50_sf, file.path(novo_dir, "p50.gpkg"), delete_dsn = TRUE)
st_write(p95_sf, file.path(novo_dir, "p95.gpkg"), delete_dsn = TRUE)
cat("Processamento e exportação concluídos.\n")