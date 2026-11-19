# iOS Application — 2GIS SDK Integration with Firebase, Routing, Localization & Chat

## Overview
This repository contains a production‑ready iOS 15+ application written in Swift 5 (UIKit) that integrates the 2GIS map and navigation SDK with Firebase services, real‑time routing, multilingual UI, voice recognition, persistent chat, and a custom neon design system. The app delivers a cohesive experience: authentication, an interactive map with routing and search, voice input, a profile/settings area, and a conversational assistant. The architecture uses Coordinators with MVC/MVVM boundaries and service abstractions for clear separation of concerns and extensibility.

---

## App Flow

### 1) Authentication → Main App
On launch, `AppDelegate`/`SceneDelegate` initialize Firebase and the 2GIS SDK. If the user is not authenticated, `AuthRootViewController` presents Login / Register / Reset Password flows (email/password via Firebase Authentication). After successful sign‑in, the app transitions to the main interface: `MapViewController` with the custom bottom tab bar overlay and the primary bottom sheet visible.

### 2) Sheet Model (Primary, Search, Info, Route)
Bottom sheets are implemented with a custom `BottomSheetViewController` that supports low/medium/high detents. Four logical sheets are used across the map experience:

- **Primary sheet** — the base sheet shown after authentication. It hosts the Search View with a microphone button. It is minimal and non‑intrusive; it establishes the sheet affordance on the map screen.
- **Search sheet** — a focused search UI with a text field and a high‑performance suggestions list. As the user types, the app calls 2GIS `SearchManager` (wrapped by `SearchService`) and updates results in real time. Results are rendered with `SuggestTripleLineCell` showing `title`, `subtitle`, and `address` distinctly. This provides fast, legible suggestions at typing speed.
- **Info sheet** — place details. It appears in two cases: (a) the user chose a suggestion in the Search sheet, in which case the camera animates to the place and the sheet presents its details; or (b) the user tapped the map. In the tap path, `MapTapInteractor` resolves the tapped object via 2GIS, the camera focuses the location, and the Info sheet shows the place info and actions (e.g., start route).
- **Route sheet** — route summary, editing, and transport mode selection. It allows editing point A and point B and choosing a transport mode (car, truck, pedestrian). The built route is drawn on the map, the camera fits the bounds, and users can start navigation.

### 3) UI Interaction and Map Controls
Sheets and map chrome are orchestrated deliberately to avoid obstruction and preserve context:
- As a sheet rises to medium/high detents, map controls dynamically hide or re‑position. For example, when the sheet covers the lower portion of the screen, the locate button shifts upward with the sheet; when the sheet reaches high, secondary controls fade out.
- `MapPaddingInteractor` updates the map content inset continuously based on the current bottom inset so markers, user location, and route geometry remain visible above the sheet.
- `VisibilityInteractor` coordinates when to hide/show map UI elements given the sheet state and navigation mode.

### 4) Bottom Tab Bar as Primary Navigation
`TabBarOverlayView` is the custom translucent neon tab bar that remains available above the content. It drives navigation between the three primary areas:
- Map (with sheets, search, info, routing),
- Chat (AI assistant view),
- Profile (settings/edit profile).
The tab bar is tightly integrated with sheet state. For example, the “Go” action in the Info sheet opens the Route sheet; after route construction and pressing “Start”, the app enters navigation; exiting navigation (via the 2GIS system sheet) returns the app to the primary sheet with the tab bar visible.

---

## Routing Details

### Transport Modes and Algorithm
`RouteService` builds routes for three modes: **car**, **truck**, and **pedestrian**. The service requests 2GIS routing with **jam** search type, which prioritizes efficient, low‑cost paths given live traffic. Routes are rendered on the map and the camera is fit using `CameraFitter` to ensure point A and point B (and polyline geometry) stay within view, accounting for the active sheet’s bottom inset.

### Excluded Areas
Routing supports **excluded areas** to avoid specific regions or segments. Three geometry types are supported:
- **Point with radius** (a circular zone defined by a center and radius),
- **Polygon** (array of points forming a closed area),
- **Polyline** (array of points representing a corridor that should be avoided; not closed like a polygon).

A minimal JSON‑style example (illustrative, aligned with the project’s usage patterns):

```json
{
  "type": "polygon",
  "severity": "hard",
  "extent": 500.0,
  "points": [
    { "latitude": 55.759909, "longitude": 37.618806 },
    { "latitude": 55.752425, "longitude": 37.613983 },
    { "latitude": 55.753567, "longitude": 37.622995 },
    { "latitude": 55.760523, "longitude": 37.625613 }
  ]
}
```

`RouteService` composes the routing request with jam mode and optional exclusion inputs, builds the preview and the final route, and emits a result to the Route sheet. After “Start”, `NavigationCoordinator` switches to turn‑by‑turn; 2GIS provides on‑map guidance and voice prompts. The user can exit navigation, which returns to the primary map state and restores the tab bar and sheets.

---

## Search and Info

- **Search**: `SearchBarView` + `EditableSearchFieldView` open the Search sheet. Each keystroke triggers `SearchService` to query 2GIS online, canceling stale requests; results are shown immediately with `SuggestTripleLineCell` (title, subtitle, address separated for readability).
- **Info**: The Info sheet appears either from a search selection or a map tap. In both cases the camera pans to the target and details are presented. Map taps are resolved by `MapTapInteractor` using 2GIS APIs, returning a place/address quickly and consistently.

---

## Voice

- **SpeechInputManager** wraps Apple Speech for streaming recognition. `VoiceListeningViewController` presents a minimal listening UI and manages partial/final text handling with a short silence timeout. On completion, the recognized text feeds directly into the Search flow.
- Voice recognition locale follows the app language so results align with the user’s selected language.

---

## Chat

- **ChatViewController / ChatViewModel** manage a conversation with an AI backend. Messages are modeled by `ChatMessage` with roles (`user`, `assistant`, `system`). The UI supports plain responses and “place cards” for map‑aware answers.
- **Persistence**: `ChatLocalStore` keeps local history; `ChatRepository` syncs to Firestore. When updates occur, both local and remote copies remain consistent.
- The chat layer is decoupled via `ChatService` (HTTP client with multiple response parsing strategies), allowing backend changes without UI refactors.

---

## Profile and Settings

- **ProfileTabViewController** presents profile rows (`ProfileRowView` / `ProfileRowKind`) for Language, Theme, Notifications, and Biometrics; **EditProfileViewController** allows avatar and display name edits (`AvatarStore`, `UserProfileStore`).
- **Localization**: Fully runtime‑switchable between Russian, Kazakh, and English. `AppLanguage` and `Utils.localize()` broadcast and apply language changes without app restart. The entire UI updates via `refreshLocalization()` implementations across controllers and views.
- **Themes**: `ThemeManager` toggles Dark/Light modes at runtime and propagates trait changes across custom UI and the 2GIS map, which supports dark style. `DesignTokens` centralize the neon palette, radii, shadows, and spacings for consistent styling.

---

## Authentication

- Currently enabled: **email/password** via Firebase Authentication.
- Extensible: Google, Apple, Facebook sign‑in can be added by wiring their providers into `AuthService` and exposing buttons on the auth screens.

---

## Technology Stack

- **Language/Frameworks**: Swift 5, UIKit, Combine.
- **Maps/Navigation**: 2GIS SDK (map view, search, routing, navigation).
- **Backend**: Firebase Authentication, Cloud Firestore.
- **Apple APIs**: CoreLocation, AVFoundation, Speech, UserNotifications.
- **Persistence**: UserDefaults (settings/profile), FileManager (avatars), Firestore (chat/cloud data).
- **Custom UI**: `BottomSheetViewController`, `TabBarOverlayView`, `HeaderBarView`, `SuggestTripleLineCell`, `PaddingLabel`, `DesignTokens`.

Minimum deployment target: **iOS 15**. Xcode 14+ recommended.

---

## Info.plist / Target Properties

Add and localize the following keys:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to show your position on the map and build routes.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location is used to provide navigation and continuous background tracking during routes.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is used for voice search and commands.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone is required for voice input.</string>

<key>GIDClientID</key>
<string>Your Google Sign-In client id (optional, if used)</string>
```

---

## Repository Notes and IP Protection

For security and contractual reasons, several core files are intentionally removed from the public repository to prevent leakage of proprietary integration logic and credentials linked to our 2GIS partnership. These include but are not limited to:

- `MapViewCoordinator.swift`
- `BottomTabBarController` / `TabBarSheetController.swift`
- `RouteService.swift`
- `SearchService.swift`
- `dgissdk.key` (2GIS SDK key file)

The repository retains complete structure and interfaces so a reviewer can understand the architecture. To run the full feature set, you must provide your own implementations and keys (or obtain the originals privately).

---

## Setup

1. Clone the repository and open the Xcode project.
2. Integrate dependencies via Swift Package Manager or CocoaPods (Firebase, 2GIS).
3. Add `GoogleService-Info.plist` to the app target.
4. Place a valid `dgissdk.key` at the project root (do not commit it).
5. Ensure Info.plist contains the privacy usage descriptions above.
6. Build and run on iOS 15+ (device or simulator). Grant permissions when prompted.

---

## Key Source Files (non‑exhaustive)

- **Auth**: `AuthRootViewController`, `LoginViewController`, `RegisterViewController`, `ResetPasswordViewController`, `AuthService`, `UserRepository`, `UserProfileStore`, `AvatarStore`.
- **Chat**: `ChatViewController`, `ChatViewModel`, `ChatService`, `ChatRepository`, `ChatLocalStore`, `ChatMessage`, `ChatMessageCell`, `Place`.
- **Map**: `MapViewController`, `OverlayController`, `MapFlowCoordinator`, `RouteFlowCoordinator`, `NavigationCoordinator`, `InfoSheetCoordinator`, `SearchSheetCoordinator`, `VoiceSheetCoordinator`, `HighlightInteractor`, `MapTapInteractor`, `MapPaddingInteractor`, `VisibilityInteractor`, `CameraFitter`, `RouteBounds`.
- **Routing/Search**: `RouteService` (omitted), `SearchService` (omitted), `RoutingState`, `RouteEditTarget`.
- **UI**: `BottomSheetViewController`, `TabBarOverlayView`, `HeaderBarView`, `SuggestTripleLineCell`, `PaddingLabel`, `DesignTokens`.
- **Settings/Profile**: `ProfileTabViewController`, `EditProfileViewController`, `ProfileRowView`, `ProfileRowKind`, `LanguageModalView`, `ThemeManager`, `AppLanguage`, `AppTheme`.
- **Voice**: `SpeechInputManager`, `VoiceListeningViewController`.

---

## Readiness
The project is engineered for publication: stable architecture, consistent runtime localization, dark/light theme integration, high‑performance search with 2GIS suggestions, robust routing with jam mode and excluded areas, turn‑by‑turn navigation, voice search, and persistent chat. Where integrations require private credentials or licensed SDK artifacts, stubs and documentation are provided so reviewers can assess design and flow without exposing sensitive assets.


---


# Documentation for llama_service

## Project Overview

llama_service is a backend service designed to provide a high-performance, self-hosted conversational AI API. Built on a lightweight Python framework, the service leverages the power of Llama models to deliver low-latency responses for a variety of natural language processing tasks. The current setup is configured to run locally and is exposed to the internet via Ngrok for testing and demonstration purposes.

## Technical Approach

The llama_service architecture is designed to be simple and efficient. It is composed of a Python application running locally inside a Docker container. This container manages all dependencies and provides a consistent environment. The application exposes its API on localhost:8000, which is then securely tunneled to the public internet using the Ngrok service.

This approach offers several key advantages:

- Containerization: Docker ensures that the application and its dependencies are portable and can be run consistently across different machines.
- Local Performance: Running the Llama model locally on a powerful machine eliminates network latency inherent in cloud-based APIs, resulting in faster response times.
- Secure Tunneling: Ngrok provides a secure, temporary public URL, allowing external access to the local service without the need for complex network configurations.

## System Architecture

### Use of LLaMA / AI

The core functionality of llama_service is powered by the Llama 4 Scout model. The service utilizes this model for general-purpose conversational tasks and text generation. The Llama model is loaded directly into the application's memory on startup, allowing for rapid inference. The model is multilingual and has been tested to work effectively with Russian, English, and Kazakh.

The model is used specifically for the following:

- Text Generation: Responding to user prompts with natural and contextually relevant text.
- Summarization: Condensing long-form text into concise summaries.
- Question Answering: Extracting and providing answers based on provided context.

We use the Llama model via a Python library (e.g., transformers or llama.cpp), which handles the model loading, tokenization, and inference, abstracting away the low-level complexities.

## Implementation Details

### API Endpoints

The service exposes a simple RESTful API. The main endpoint is `/v1/chat/completions`.

- **Endpoint**: `POST /v1/chat/completions`
- **Description**: Processes a user's chat message and returns a response from the Llama model.
- **Request Body (JSON)**:

```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant."
    },
    {
      "role": "user",
      "content": "What is the capital of France?"
    }
  ],
  "model": "llama-4-scout"
}
```

- **Response Body (JSON)**:

```json
{
  "id": "cmpl-01",
  "object": "chat.completion",
  "created": 12345678,
  "model": "llama-4-scout",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "The capital of France is Paris."
      }
    }
  ]
}
```

### Configuration

For a production environment, the API key for Groq Cloud is used to access the Llama model. This key is considered sensitive information and is not committed to the GitHub repository for security reasons. Instead, it is managed as an environment variable within the `.env` file.

### Dependencies

- Python: The service is written in Python.
- Docker: Used for packaging the application and its environment.
- Ngrok: Provides a secure tunnel for public access.

## Demo Instructions

To test the llama_service, please follow these steps:

1. **Clone the Repository**:

   ```bash
   git clone [https://github.com/your-username/llama_service.git](https://github.com/your-username/llama_service.git)
   cd llama_service
   ```

   *(Note: This is a placeholder; please update with the actual repository URL.)*

2. **Set Up Environment Variables**:  
   Create a `.env` file in the root directory with your Ngrok authtoken and your Groq Cloud API key.

   ```env
   NGROK_AUTHTOKEN=<YOUR_NGROK_AUTH_TOKEN>
   GROQ_API_KEY=<YOUR_GROQ_API_KEY>
   ```

3. **Build and Run the Docker Container**:

   ```bash
   docker-compose up --build
   ```

   This command will build the Docker image and start the service on `http://localhost:8000`.

4. **Start Ngrok**:  
   In a new terminal window, use the Ngrok client to expose the local service.

   ```bash
   ngrok http 8000
   ```

   Ngrok will provide a public URL. Copy this URL to use in the next step.

5. **Test the API**:  
   Use a tool like cURL or Postman to send a POST request to the Ngrok public URL.

   ```bash
   curl -X POST <NGROK_URL>/v1/chat/completions \
   -H "Content-Type: application/json" \
   -d '{
     "messages": [
       {"role": "user", "content": "Объясни важность LLM с низкой задержкой."}
     ],
     "model": "llama-4-scout"
   }'
   ```

   The response will be the generated text from the Llama model.


---

# Computer Vision Models Documentation

## Astanaflood

### Purpose

The Astanaflood project uses semantic segmentation based on a YOLOv11 model to accurately identify and delineate flooded areas (roads, buildings) in aerial imagery.

### Dataset and Analysis

- **Source**: A dataset from Roboflow containing 480 images.
- **Source Link**: https://universe.roboflow.com/project-us7um/flood-sjsky
- **Classes**: background, building flooded, building non-flooded, grass, pool, road flooded, road non-flooded, tree, vehicle, water.
- **Data Preparation**: Images were resized to 640x640 and augmented with techniques like horizontal/vertical flips, rotations, and cropping to expand the training set.
- **Analysis**: The model analyzes each image pixel by pixel to create a mask for each class, showing the precise location of flooded areas.

### Metrics

The model's performance is evaluated using standard semantic segmentation metrics:

- **mAP (mean Average Precision) @ 0.5**: Evaluates segmentation accuracy.
- **mAP (mean Average Precision) @ 0.5:0.95**: A strict metric for assessing the accuracy of segmentation boundaries.
- **P (Precision)**: Measures the accuracy of the model's positive predictions.
- **R (Recall)**: Measures the model's ability to find all the positive instances.
  
```
YOLO11n summary (fused): 100 layers, 2,582,347 parameters, 0 gradients, 6.3 GFLOPs
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95)
                   all         40         45      0.723      0.622      0.694      0.269
```
<img width="1489" height="402" alt="image" src="https://github.com/user-attachments/assets/08698fd4-aa05-47cd-a43a-fd0aa10ef325" />


### Usage

You can run this project using either the Jupyter Notebook (`floodastana.ipynb`) or a Python script.

#### Running with Jupyter Notebook (`floodastana.ipynb`)

Simply open the file in Jupyter or Google Colab and run all cells sequentially. The notebook contains the code to install dependencies, configure paths, and run inference on test images.

#### Running with a Python Script

1. Install the required libraries, for example:

   ```bash
   pip install ultralytics
   ```

2. Run inference on an image using code similar to that in the notebook (`floodastana.ipynb`):

   ```python
   from ultralytics import YOLO
   import cv2
   import os

   model = YOLO('path/to/your/best.pt') # Load the trained model
   image_path = 'path/to/your/image.jpg'
   results = model(image_path, conf=0.25)
   result_image = results[0].plot()
   cv2.imwrite('result.jpg', result_image)
   ```

---

## Astanasnow

### Purpose

The Astanasnow project is an object detection solution based on YOLOv11 designed to classify road conditions into three classes: Snow_road, clear-road, and object.

### Dataset and Analysis

- **Source**: The "Snow Detection v2" dataset from Roboflow, which includes 2152 images.
- **Source Link**: https://universe.roboflow.com/snow-z6okt/snow-detection
- **Classes**: Snow_road, clear-road, object.
- **Data Preparation**: Images were resized to 640x640. No augmentation was applied.
- **Analysis**: The model predicts bounding boxes and class labels for each detected object.

### Metrics

Model performance is evaluated using object detection metrics:

```
   Class       Images  Instances      Box(P          R      mAP50  mAP50-95):
       all        120        127      0.891      0.502      0.563      0.457
 Snow_road         55         58      0.837      0.793      0.852       0.77
clear-road         57         64      0.835      0.713      0.825      0.599
```

<img width="2250" height="1500" alt="BoxP_curve" src="https://github.com/user-attachments/assets/94afaf1a-e125-4ee2-8a52-6f1c47e0f61c" />
<img width="2250" height="1500" alt="BoxPR_curve" src="https://github.com/user-attachments/assets/5c8c59c6-cde1-4380-b039-6a37be77150b" />


### Usage

You can run the project using either the Python script (`astanasnow.py`) or the Jupyter Notebook (`astanasnow.ipynb`).

#### Running with Jupyter Notebook (`astanasnow.ipynb`)

Open the notebook in Jupyter or Google Colab and run the cells. The notebook will guide you through the process of training the model and performing inference.

#### Running with Python Script (`astanasnow.py`)

1. Ensure you have the ultralytics library installed.

2. Update the path to your dataset in the `astanasnow.py` file:

   ```python
   DATASET_PATH = 'path/to/your/data.yaml'
   ```

3. Run the script from the command line for training:

   ```bash
   python astanasnow.py train
   ```

4. To perform inference on new images:

   ```bash
   python astanasnow.py predict
   ```

---

## Astanaice

### Purpose

The Astanaice project is a semantic segmentation solution based on YOLOv11 for detecting icy patches on roads and sidewalks.

### Dataset and Analysis

- **Source**: The "ice detection3" dataset from Roboflow, containing 785 images.
- **Source Link**: https://universe.roboflow.com/asd-gamhj/ice-detection3-8pmcw
- **Classes**: A single class, ice.
- **Data Preparation**: No augmentation was applied. PNG masks are used for semantic segmentation.
- **Analysis**: The model generates a mask for each image to precisely highlight areas covered in ice.

### Metrics

- Mean Average Precision (mAP) at IoU 0.5: 0.7152
- Mean Average Precision (mAP) at IoU 0.5-0.95: 0.3483

```
Class     Images  Instances      Box(P          R      mAP50  mAP50-95)     Mask(P          R      mAP50  mAP50-95)
  all        154        242      0.742      0.653      0.709      0.372      0.681      0.727      0.715      0.348
```

<img width="2250" height="1500" alt="BoxP_curve" src="https://github.com/user-attachments/assets/575dceb6-989b-4e81-93ec-6262ab44b442" />
<img width="2250" height="1500" alt="BoxPR_curve" src="https://github.com/user-attachments/assets/e0a9ed31-09bc-421f-a082-374ce4e5ec44" />


### Usage

You can run this project using either the Python script (`icenet_finetuned.py`) or the Jupyter Notebook (`icenet_finetuned.ipynb`).

#### Running with Jupyter Notebook (`icenet_finetuned.ipynb`)

Open the file in Jupyter or Google Colab and execute the cells. The notebook includes instructions for installation, training, and inference.

#### Running with a Python Script (`icenet_finetuned.py`)

1. Install ultralytics.

2. Update the paths to your model and images in the `icenet_finetuned.py` file.

3. Run the script to perform inference:

   ```bash
   python icenet_finetuned.py
   ```

The script will run inference and save the results to the specified folder.

---

# Car Detection Astana

## Install and Import Dependencies

```bash
!pip install -U "numpy>=2.0,<2.3" "ultralytics>=8.3.20" "opencv-python-headless>=4.10,<4.13" -q
```

- **numpy**: numerical computing (version 2.0-2.2)
- **opencv-python-headless**: OpenCV without GUI dependencies for image processing

### Instruments

- **Python**: 3.12.11
- **Torch**: 2.8.0+cu126
- **CUDA available**: True
- **GPU**: NVIDIA L4
- **GPU 0**: NVIDIA L4 (UUID: GPU-d3e2c9d8-0de1-2393-9463-10bb95848de4)

## Data Preparation

### All links

- **Dataset**: https://drive.google.com/drive/folders/1zRjOt0mEd3b55mfztDL7DJTHqKiv3a4_?usp=sharing
- **Dataset 8 Astana Test Images**: https://drive.google.com/drive/folders/1QFbJYjlL01d2tah__bTQd7TWBtCEklMO?usp=sharing

### DATA

- **YAML**: /content/drive/MyDrive/Car_Detection_DATA/data.yaml
- **Classes (nc=23)**: ['auto', 'bicycle', 'bike', 'board', 'building', 'bus', 'car', 'cars', 'divider', 'milestone', 'motor', 'motorbike', 'person', 'rider', 'signboard', 'stop sign', 'street light', 'tower', 'tractor', 'traffic light', 'tree', 'truck', 'van']
- **Split sizes**:
  - Train: 14,026 images, 14,019 labels
  - Val: 1,334 images, 1,334 labels
  - Test: 667 images, 667 labels
- **Loader mode**: rect=True (aspect-ratio preserving batches). Note: this forces shuffle=False (Ultralytics warning is expected).

### Stages

- **Environment readiness**: all required libraries installed with correct versions.
- **Drive connectivity**: dataset is accessible from Google Drive.
- **Configuration integrity**: data.yaml exists and correctly defines paths and classes.
- **Dataset completeness**: nearly one-to-one match between images and label files in each split.
- **Annotation validity**: YOLO-formatted labels with correct class IDs and normalized coordinates.

## Model Parameters and Training Process

### MODEL

- **YOLOv8-S (yolov8s.pt)**: small, fast baseline to establish a clean reference.
- **imgsz=512, batch=96**: fits in 22.7 GB VRAM on L4 with AMP; good throughput.
- **cache="ram"**: eliminates repeated disk I/O, speeding up epochs.
- **Minimal augmentation**: set all heavy/mixing augments to 0.0 for a controlled baseline.
- **rect=True**: preserves aspect ratio for traffic imagery; improves small-object stability.
- **Backbone/Head**: YOLOv8-S, 11.14M params, 28.7 GFLOPs
- **Optimizer**: AdamW (lr is good)
- **box_loss**: 1.426
- **dfl_loss**: 1.291
- **mosaic**: Precision 0.637, Recall 0.186, mAP@50 0.199, mAP@50-95 0.128

### Performance Notes

Many of the classes in the dataset (for example divider, board, tower, stop sign, tractor) are rare and largely irrelevant to congestion monitoring. Because these seldom-seen categories naturally produce very low recall and mAP, their near-zero scores drag down the global averages.

For the classes that actually matter for vehicle traffic, the model performs far better:

- **car**: mAP@50 0.545 (P 0.433 | R 0.732)
- **bicycle**: mAP@50 0.600 (P 0.571 | R 0.633)

These per-class results give a much more realistic picture of how well the model detects the key objects for traffic-congestion monitoring. When reporting results or making decisions based on them, focus on the vehicle-related metrics rather than the raw overall mAP.

### Evaluation Visualizations (Confusion Matrix + Curves)

As noted earlier, overall mAP is averaged over all 23 classes, including many rare/irrelevant ones. These plots let you zero-in on the classes that matter for traffic (car, truck, bus, bicycle, traffic light), revealing true operating characteristics and common confusions fewer, more confident detections. Lower threshold (e.g. 0.15) evaluation real-world inference.

## Traffic Congestion Estimation

This step turns detections into simple, interpretable traffic metrics per image and saves both annotated previews and a CSV report.

### What the script does

1. Loads your trained detector: best.pt from Section 4.
2. Runs inference on every image in DATA_Test.
3. Filters classes to vehicles: {car, truck, bus, van} (editable via VEHICLE_CLASSES).
4. Defines a road ROI (bottom ~55% of the image by default) with road_roi_mask().
5. Computes per-image metrics:
   - **Count**: number of vehicle boxes above CONF_THR inside ROI.
   - **Occupancy**: (|ROI| / |ROI|)
   - **Saturation (0-1)**: balanced blend of area and count
   - **TCI**: 0.5 * saturation
   - **Level (categorical)**: Low (<0.25), Moderate (<0.50), High (<0.75), Critical

### Assumptions & Caveats

- ROI is a proxy for the drivable area; for angled cameras, a custom polygon ROI improves accuracy.
- Bounding boxes how many cars fit.
- Use TCI to rank scenes and trigger alerts, not as a legal/official measure.

---

# Road Accidents Heatmap

## Overview

The Road Accidents Heatmap project builds an interactive Leaflet map to visualize road accident data as a heatmap, using `pyproj` for data manipulation. The heatmap highlights areas of high accident density based on a dataset containing accident records with date, latitude, and longitude information.

## How to Run

1. **Open the Notebook in Google Colab and Mount Your Google Drive**:
   - Open the Jupyter notebook in Google Colab.
   - Mount your Google Drive to access the dataset and save outputs.

2. **Place the Dataset CSV into Your Google Drive**:
   - Ensure the dataset CSV file is uploaded to your Google Drive in a location accessible by the notebook.

3. **Execute the Notebook Cells**:
   The script will perform the following steps:
   - **Detect Columns**: Automatically identify date/year, latitude, and longitude columns in either Russian or English.
   - **Filter Data**: Filter the dataset to include only records from the last 5 years, based on a Date or Year column.
   - **Coordinate Conversion**: Check if coordinates are in Web Mercator (EPSG:3857). If so, convert them to WGS84 (EPSG:4326) using `pyproj`.
   - **Data Cleaning**: Remove invalid or out-of-bounds coordinates to ensure accurate plotting.

4. **Generate the Heatmap**:
   - Each accident record is plotted as a point on the map.
   - Optionally, points can be weighted by the number of casualties if a casualties column exists in the dataset.
   - Customize the heatmap's appearance using parameters like `radius`, `blur`, or `min_opacity` to control its look and sensitivity.

5. **View the Result**:
   - The notebook generates an interactive HTML file and saves it to your Google Drive at: `/content/drive/MyDrive/dtp_heatmap_last5y.html`.

## Notes & Tips

- **Date Handling**: If no valid date column is found, the script will fall back to using a Year column for filtering.
- **Empty Dataset After Filtering**: If no rows remain after filtering, verify that the dataset contains records from the last 5 years.
- **Heatmap Customization**: Adjust the `radius` parameter to control the heatmap's appearance. Increase the radius for larger, more spread-out clusters or decrease it for finer, more detailed clusters.
- **Output Example**: The resulting interactive HTML map displays bright clusters indicating areas of high accident density over the past five years.
