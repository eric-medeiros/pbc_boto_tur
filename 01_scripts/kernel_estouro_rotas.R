# Pacotes
library(here)
library(sf)
library(spatstat)
library(terra)
library(dplyr)

# ---- Caminhos ----
pasta_data    <- here("00_data")
pasta_output  <- here("02_outputs", "turistas_estouro")

caminho_pontos_boto_estouro <- list.files(pasta_data, "Pontos_Botos_Estouro", full.names = TRUE)
caminho_trajetos_estouro    <- list.files(pasta_data, "Linhas_Trajeto_Estouro", full.names = TRUE)
caminho_agua                <- here(pasta_data, "Poligs_Agua_Estouro.gpkg")

caminho_pontos   <- here(pasta_output, "pontos.gpkg")
caminho_trajetos <- here(pasta_output, "trajetos.gpkg")
caminho_kernel   <- here(pasta_output, "kernel.tif")
caminho_p95      <- here(pasta_output, "p95.gpkg")
caminho_p50      <- here(pasta_output, "p50.gpkg")

if (!dir.exists(pasta_output)) dir.create(pasta_output, recursive = TRUE)

# ---- Função para calcular limiar ----
calcular_limiar <- function(raster, prob) {
  valores <- terra::values(raster, na.rm = TRUE)
  valores <- sort(valores, decreasing = TRUE)
  soma_acum <- cumsum(valores)
  total <- sum(valores)
  limiar <- valores[which.max(soma_acum >= (prob * total))]
  return(limiar)
}

# ---- Leitura dos dados ----
pontos <- st_read(caminho_pontos_boto_estouro, quiet = TRUE) %>% st_transform(31983)
trajetos <- st_read(caminho_trajetos_estouro, quiet = TRUE) %>% st_transform(31983)
area <- st_read(caminho_agua, quiet = TRUE) %>% st_transform(31983)

# ---- Conversão para spatstat ----
win <- as.owin(area)
trajetos_sel <- trajetos %>% filter(!st_is_empty(geom)) %>% st_cast("LINESTRING")
trajetos_psp <- as.psp(trajetos_sel$geom, W = win)

# ---- Densidade ----
dens <- density.psp(trajetos_psp,
                    sigma = 500, 
                    method = "FFT", 
                    edge = TRUE, 
                    dimyx = c(300, 300))

# Ajustar para área de estudo
dens_raster <- rast(dens)
crs(dens_raster) <- "EPSG:31983"
dens_raster <- crop(dens_raster, vect(area), mask = TRUE)

# ---- Limiar 50 e 95 ----
limiar_50 <- calcular_limiar(dens_raster, 0.50)
limiar_95 <- calcular_limiar(dens_raster, 0.95)

mascara_50 <- classify(dens_raster, cbind(-Inf, limiar_50, NA))
mascara_95 <- classify(dens_raster, cbind(-Inf, limiar_95, NA))

p50 <- as.polygons(mascara_50, dissolve = TRUE) %>% st_as_sf()
p95 <- as.polygons(mascara_95, dissolve = TRUE) %>% st_as_sf()

# ---- Exporta ----
st_write(pontos, caminho_pontos, delete_dsn = TRUE)
st_write(trajetos_sel, caminho_trajetos, delete_dsn = TRUE)
writeRaster(dens_raster, caminho_kernel, overwrite = TRUE)
st_write(p50, caminho_p50, delete_dsn = TRUE)
st_write(p95, caminho_p95, delete_dsn = TRUE)
