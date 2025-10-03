library(here)
library(sf)
library(spatstat)
library(terra)
library(dplyr)


# caminhos
pasta_data <- here("00_data")
caminho_pontos_boto <- list.files(here(pasta_data), "Pontos_Botos_Espacial", full.names = TRUE)
caminho_trajetos_campos <- list.files(here(pasta_data), "Linhas_Trajeto_Espacial", full.names = TRUE)
caminho_agua <- here(pasta_data, "Poligs_agua_Espacial.gpkg")
pasta_output <- here("02_outputs", "botos_campos")

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
  st_read(caminho_pontos_boto, quiet = TRUE) %>%
  st_transform(31983) %>%
  mutate(ano = lubridate::year(data),
         tam_grupo = as.numeric(tam_grupo),
         tam_min = as.numeric(tam_min), 
         tam_max = as.numeric(tam_max),
         tam = case_when(is.na(tam_grupo) ~ floor((tam_min + tam_max)/2),
                         .default = tam_grupo)) %>%
  filter(!is.na(tam))

trajetos <-
  st_read(caminho_trajetos_campos, quiet = TRUE) %>%
  st_transform(31983) %>%
  mutate(ano = lubridate::year(data_rota))

area <-
  st_read(caminho_agua, quiet = TRUE) %>%
  st_transform(31983)

# janela para o spatstat
win <- as.owin(area)

# Cria pasta outputs, caso não exista
if (!dir.exists(pasta_output)) { dir.create(pasta_output) }

for (ano in unique(pontos$ano)) {
  
  caminho_pasta_ano <- here(pasta_output, ano)
  # Cria pasta ano, caso não exista
  if (!dir.exists(caminho_pasta_ano)) { dir.create(caminho_pasta_ano) }
  
  caminho_pontos <- here(caminho_pasta_ano, "pontos.gpkg")
  caminho_trajetos <- here(caminho_pasta_ano, "trajetos.gpkg")
  caminho_kernel <- here(caminho_pasta_ano, "kernel.tif")
  caminho_p95 <- here(caminho_pasta_ano, "p95.gpkg")
  caminho_p50 <- here(caminho_pasta_ano, "p50.gpkg")
  
  pontos_sel <- pontos[pontos$ano == ano,] %>% arrange(data, grupo)
  trajetos_sel <- trajetos[trajetos$ano == ano,] %>% arrange(data_rota)
  
  pontos_ppp <- 
    pontos_sel %>%
    st_intersection(area) %>%
    as.ppp(W = win)
  
  dens <- density.ppp(pontos_ppp, 
                      weights = marks(pontos_ppp)$tam, 
                      sigma = 500, # raio do kernel em metros
                      edge = TRUE)
  
  dens_raster <- rast(dens)
  crs(dens_raster) <- "EPSG:31983"
  
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
  pontos_sel %>% st_write(caminho_pontos, delete_dsn = TRUE)
  trajetos_sel %>% st_write(caminho_trajetos, delete_dsn = TRUE)
  dens_raster %>% writeRaster(caminho_kernel, overwrite = TRUE)
  p95 %>% st_write(caminho_p95, delete_dsn = TRUE)
  p50 %>% st_write(caminho_p50, delete_dsn = TRUE)
}
