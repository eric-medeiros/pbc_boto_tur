calcular_limiar <- function(raster, prob) {
  valores <- terra::values(raster, na.rm = TRUE)
  valores_ordenados <- sort(valores, decreasing = TRUE)
  soma_acumulada <- cumsum(valores_ordenados)
  total <- sum(valores_ordenados)
  indice_limiar <- which.max(soma_acumulada >= (prob * total))
  
  result <- valores_ordenados[indice_limiar] 
  
  return(result)
}