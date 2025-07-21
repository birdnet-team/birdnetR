---
title: 'birdnetR: An R package for interfacing with BirdNET for automated (bird) sound identification'
tags:
  - R
  - bioacoustics
  - machine learning
  - deep learning
  - sound identification
  - ecology
  - ornithology
authors:
  - name: Felix Günther
    orcid: # TODO: Add ORCID
    affiliation: 1
  - name: Stefan Kahl
    orcid: # TODO: Add ORCID
    affiliation: "1, 2"
affiliations:
 - name: Chemnitz University of Technology, Germany
   index: 1
 - name: K. Lisa Yang Center for Conservation Bioacoustics, Cornell Lab of Ornithology, Cornell University, USA
   index: 2
date: 5 May 2025 # TODO: Update if needed
bibliography: library.bib
---

# Summary

`birdnetR` is a package for the R programming language [@RCoreTeam2024] that provides an interface to BirdNET [@Kahl2021BirdNETAD], a state-of-the-art deep learning system for automated bird sound identification. It allows researchers and practitioners working within the R environment to analyze audio recordings using pre-trained BirdNET models or custom-trained classifiers. Key functionalities include identifying species within audio files and predicting likely species occurrence based on geographic location and time of year. `birdnetR` simplifies the integration of powerful machine learning tools into bioacoustic analysis workflows, making them accessible even without extensive computer science expertise.

# Statement of Need

The analysis of large bioacoustic datasets is crucial for biodiversity monitoring and ecological research. BirdNET offers a well-established and widely used solution for automated species identification from sound recordings [@Cole2022May, @perez2023birdnet, @fairbairn2024birdnet, @wood2024scalable, @Mann2025Apr].
BirdNET is primarily accessible as a Python package [@birdnet_python] and as the BirdNET-Analyzer [@birdnet_analyzer], which offers both graphical (GUI) and command-line (CLI) interfaces.

However, its primary implementation is in Python, potentially creating a barrier for researchers using the R statistical environment, a popular language for data analysis and visualization, especially in environmental sciences.

`birdnetR` bridges this gap by wrapping the `birdnet` Python package [@birdnet_python], enabling easy integration into R-based workflows. This facilitates the use of BirdNET's capabilities for tasks such as analyzing soundscape recordings, processing data from acoustic monitoring projects, and filtering species lists based on expected occurrence, directly within R.

# State of the Field

Several tools exist for bioacoustic analysis in R, such as `seewave` [@seewave], `tuneR` [@tuneR], and `warbleR` [@warbleR], which offer functionalities for sound manipulation, measurement, and visualization. Packages like `monitoR` [@monitoR] and [@ohun] provide tools for sound event detection and acoustic template matching.
However, using pre-trained, state-of-the-art deep learning models like BirdNET for species identification directly within R has been less straightforward.

While the underlying `birdnet` Python package provides comprehensive analysis capabilities, `birdnetR` specifically targets R users, offering a simplified interface for the most common BirdNET tasks, complementing existing R bioacoustics packages by adding robust, AI-driven species identification. It focuses on ease of use for applying pre-existing models rather than model training, for which the original BirdNET-Analyzer [@birdnet_analyzer] is recommended.

# Key Functionality

`birdnetR` provides functions to:

* **Initialize BirdNET models:** load pre-trained BirdNET models (TensorFlow Lite or Protobuf versions) or custom-trained classifiers. Handles model downloading and setup via `reticulate`. (`birdnet_model_tflite()`, `birdnet_model_protobuf()`, `birdnet_model_custom()`)
* **Analyze audio files:** Process audio files (e.g., WAV, MP3) to identify bird species within 3-second segments, returning confidence scores for each detection. (`predict_species_from_audio_file()`)
* **Filter results:** Optionally filter detections by a minimum confidence threshold or limit results to a user-provided species list.
* **Process predictions:** Helper function to extract the most probable species prediction for each time interval. (`get_top_prediction()`)
* **Predict species occurrence:** Utilize the BirdNET Meta Model to predict the likelihood of species presence based on latitude, longitude, and week of the year. (`predict_species_at_location_and_time()`)
* **Manage labels:** Retrieve paths to model label files and support multiple languages for common names. (`labels_path()`, `available_languages()`, `read_labels()`)


# Acknowledgements

We acknowledge the original BirdNET team for developing the underlying models and Python software. Development of `birdnetR` was supported by [TODO: Add any specific funding for the R package itself, if different from the main BirdNET funding]. The development of BirdNET is supported by the German Federal Ministry of Education and Research (Project “BirdNET+”, FKZ 01|S22072), the German Federal Ministry for the Environment, Nature Conservation and Nuclear Safety (Project “DeepBirdDetect”, FKZ 67KI31040E), and the Deutsche Bundesstiftung Umwelt (Project “RangerSound”, project 39263/01). Work at the K. Lisa Yang Center for Conservation Bioacoustics is supported by Jake Holshuh (Cornell class of '69), The Arthur Vining Davis Foundations, and K. Lisa Yang.

# References
