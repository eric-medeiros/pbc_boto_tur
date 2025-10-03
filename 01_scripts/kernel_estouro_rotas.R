library(here)
library(sf)
library(spatstat)
library(terra)
library(dplyr)

# caminhos
pasta_data <- here("00_data")
caminho_pontos_boto_estouro <- list.files(here(pasta_data), "Pontos_Botos_Estouro", full.names = TRUE)
caminho_trajetos_estouro <- list.files(here(pasta_data), "Linhas_Trajeto_Estouro", full.names = TRUE)
caminho_agua <- here(pasta_data, "Poligs_agua_Estouro.gpkg")
pasta_output <- here("02_outputs", "turistas_estouro")
caminho_pontos <- here(pasta_output, "pontos.gpkg")
caminho_trajetos <- here(pasta_output, "trajetos.gpkg")
caminho_kernel <- here(pasta_output, "kernel.tif")
caminho_p95 <- here(pasta_output, "p95.gpkg")
caminho_p50 <- here(pasta_output, "p50.gpkg")

# função para calcular limiar
calcular_limiar <- function(raster, prob) {
  valores <- terra::values(raster, na.rm = TRUE)
  valores_ordenados <- sort(valores, decreasing = TRUE)
  soma_acumulada <- cumsum(valores_ordenados)
  total <- sum(valores_ordenados)
  indice_limiar <- which.max(soma_acumulada >= (prob * total))
  result <- valores_ordenados[indice_limiar] 
  return(result)
}

# Leitura dos dados geo refs
pontos <-
  st_read(caminho_pontos_boto_estouro, quiet = TRUE) %>%
  st_transform(31983)

trajetos <-
  st_read(caminho_trajetos_estouro, quiet = TRUE) %>%
  st_transform(31983)

area <-
  st_read(caminho_agua, quiet = TRUE) %>%
  st_transform(31983)

# janela para o spatstat
win <- as.owin(area)

# Cria pasta outputs, caso não exista
if (!dir.exists(pasta_output)) { dir.create(pasta_output) }

trajetos_sel <-
  trajetos %>%
  filter(!st_is_empty(geom)) %>%
  st_intersection((area)) %>%
  st_cast("LINESTRING")

trajetos_psp <-
  trajetos_sel$geom %>%
  as.psp(W = win)

dens <- density.psp(trajetos_psp,
                    sigma =  500, # raio do kernel em metros
                    method = "interpreted",
                    edge = TRUE)

dens_raster <- rast(dens)
crs(dens_raster) <- "EPSG:31983"
ext(dens_raster) <- ext(vect(area))

dens_raster <- crop(dens_raster, vect(area), mask = TRUE, extend = TRUE)

# calcular o limiar para 50 e 95
limiar_50 <- calcular_limiar(dens_raster, 0.50)
limiar_95 <- calcular_limiar(dens_raster, 0.95)

# criar máscara: mantém apenas valores >= limiar, NA nos demais
mascara_95 <- dens_raster
mascara_95[mascara_95 < limiar_95] <- NA

mascara_50 <- dens_raster
mascara_50[mascara_50 < limiar_50] <- NA

# converter para polígonos para depois
p95 <-
  as.polygons(mascara_95, dissolve = TRUE) %>%
  st_as_sf()
p50 <-
  as.polygons(mascara_50, dissolve = TRUE) %>%
  st_as_sf()

# salva pontos de dados, raster de kernel e polígonos de p50 e p95 como arquivo georreferenciado
pontos %>% st_write(caminho_pontos, delete_dsn = TRUE)
trajetos_sel %>% st_write(caminho_trajetos, delete_dsn = TRUE)
dens_raster %>% writeRaster(caminho_kernel, overwrite = TRUE)
p95 %>% st_write(caminho_p95, delete_dsn = TRUE)
p50 %>% st_write(caminho_p50, delete_dsn = TRUE)
