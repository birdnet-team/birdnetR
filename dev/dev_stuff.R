library(reticulate)

py_birdnet <- import("birdnet")
str(py_birdnet)


py_birdnet <- reticulate::import("birdnet")

bn_globals <- py_birdnet$globals
bn_globals$ACOUSTIC_MODEL_VERSIONS
bn_globals$MODEL_PRECISIONS

# tf library
py_birdnet$load("acoustic", "2.4", "tf", library = "litert")
py_birdnet$load("acoustic", "2.4", "tf", library = "tflite")

# tf precision
py_birdnet$load("acoustic", "2.4", "tf", precision = "int8")
py_birdnet$load("acoustic", "2.4", "tf", precision = "fp16")
py_birdnet$load("acoustic", "2.4", "tf", precision = "fp32")

# protobuf
py_birdnet$load("acoustic", "2.4", "pb")

# xxx
py_birdnet$load("acoustic", "2.4", "pb", library = "litert")
py_birdnet$load("acoustic", "2.4", "pb", precision = "fp16")

# geo
py_birdnet$load("geo", "2.4", "tf")
py_birdnet$load("geo", "2.4", "pb")

# custom
py_birdnet$load_custom(
  "acoustic",
  "2.4",
  "tf",
  "path/to/model",
  "path/tp/specislist"
)
py_birdnet$load_custom("geo", ...)


py_birdnet_globals <- import("birdnet.globals")


devtools::load_all()

model_int8 <- load_model(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  precision = "int8"
)

model_fp32 <- load_model(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  precision = "fp32"
)
model_fp16 <- load_model(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  precision = "fp16"
)

model_g <- load_model(
  type = "geo",
  version = "2.4",
  backend = "tf",
  library = "tf",
  precision = "fp32"
)
model_g

mod_c <- load_custom(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  precision = "fp32",
  model = "/Volumes/OekoFor_Daten/BirdNet_Training/Recent_Classifier/Custom_Classifier.tflite",
  labels = "/Volumes/OekoFor_Daten/BirdNet_Training/Recent_Classifier/Custom_Classifier_Labels.txt",
  check_validity = TRUE
)
mod_c


model_c <- load_custom(
  type = "acoustic",
  version = "2.4",
  backend = "pb",
  precision = "fp32",
  model = "/Users/fegue/Downloads/BirdNET_GLOBAL_3K_V2.3_Model/BirdNET_GLOBAL_3K_V2.3_Model/",
  labels = "/Users/fegue/Downloads/BirdNET_GLOBAL_3K_V2.3_Model/BirdNET_GLOBAL_3K_V2.3_Labels.txt",
  check_validity = TRUE
)


files = c(
  system.file("extdata", "soundscape.mp3", package = "birdnetR"),
  "/Users/fegue/Downloads/ML47878591_Trinidad-Guan.mp3"
)

res = predict(model_fp32, files)
reas = res$py_predictions$to_arrow_table()
reas = reas$group_by("file_path")
py_arrow <- import("pyarrow")
py_arrow_csv <- py_arrow$csv

for (group in reas) {
  keys <- group[[1]]
  group_tbl <- group[[2]]
  file_path <- keys$get("file_path")$as_py()

  # Sanitize file_path to use as filename
  safe_path <- gsub("[/\\\\]", "_", file_path)

  # Write to CSV
  py_arrow_csv$write_csv(group_tbl, paste0(safe_path, ".csv"))
}

for (i in reas) {
  print(i)
}


many_files <- list.files(
  "/Volumes/Extreme SSD/audio_datasets/WABAD_normalized/",
  full.names = TRUE,
  recursive = TRUE,
  pattern = "*.wav"
) |>
  reticulate::as_iterator()

res_many <- model_fp32$py_model$predict(many_files, show_stats = "progress")
