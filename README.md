# 🐬 pbc_boto_tur

Análises espaciais de **botos-cinza (Sotalia guianensis)** e de **rotas de turistas** em Cananéia-SP.  
O projeto organiza scripts em **R** que processam dados geográficos, geram densidades kernel e apresentam resultados em um **flexdashboard interativo**.

---

## 📂 Estrutura do repositório

- **00_data/**  
  📊 Dados brutos de pontos, trajetos e áreas de água em formato `gpkg`.

- **01_scripts/**  
  ⚙️ Scripts em R para processamento espacial:  
  - `kernel_boto_ano.R` → Densidade kernel de **pontos de botos observados** em campo.  
  - `kernel_estouro_rotas.R` → Densidade kernel de **trajetos de embarcações/turistas (estouro)**.  

- **02_outputs/**  
  📁 Resultados exportados:  
  - `pontos.gpkg`, `trajetos.gpkg` → dados vetoriais.  
  - `kernel.tif` → raster de densidade kernel.  
  - `p50.gpkg`, `p95.gpkg` → polígonos de 50% e 95% de densidade.

- **markdown/**  
  📑 Dashboard interativo em **html** com mapas em `leaflet`.

- **pbc_boto_tur.Rproj**  
  🎯 Arquivo de projeto do RStudio.

---

## 🔧 Requisitos

O projeto foi desenvolvido em **R**.  
Principais pacotes:

- `sf`
- `terra`
- `spatstat`
- `dplyr`
- `leaflet`
- `flexdashboard`
- `lubridate`
- `here`

---

## 🚀 Como usar

1. Clone o repositório:
   ```bash
   git clone https://github.com/eric-medeiros/pbc_boto_tur.git
   ```

2. Execute os scripts de processamento em `01_scripts/`.  
   - Para **botos em campo**: gera pontos, trajetos, raster kernel, p50 e p95 por ano.  
   - Para **turistas/estouro**: gera densidade kernel de trajetos, pontos e polígonos p50/p95.

3. Rode o arquivo **markdown** no RStudio para visualizar o **mapa interativo**:  
   - Alternar camadas (pontos, trajetos, kernel, P50, P95).  
   - Visualizar informações detalhadas ao clicar nos pontos.

---

## 📊 Saídas esperadas

- ✅ Arquivos georreferenciados (`gpkg`, `tif`) organizados por ano.  
- 🌐 Dashboard interativo com sobreposição de camadas em `html`.  
- 🎨 Visualização comparativa entre rotas dos botos e rotas de turistas.

---

## 👤 Autor

**Eric Medeiros**  
Projeto desenvolvido para análise espacial do turismo náutico em Cananéia-SP. Os dados foram gerados no aplicativo Estouro do Projeto Boto-Cinza do Instituto de Pesquisas Cananéia.
🐬🌊📍
