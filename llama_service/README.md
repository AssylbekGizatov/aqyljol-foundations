# LLAMA API GUIDE

## 1.0 Project Description

This project is a **FastAPI** application designed to serve as an AI-powered city guide for **Astana, Kazakhstan**. It receives user location data and a text query, then utilizes a large language model to generate structured information about nearby places in **JSON** format.

The application uses the **Llama 3 (70B)** model for its advanced generative capabilities and leverages the **Groq API** to ensure low-latency, high-speed inference. This architecture eliminates the need for managing a dedicated GPU infrastructure.

## 2.0 Features

- **High-Performance Inference**: The application is powered by the Groq API for rapid response times.
- **Contextual Awareness**: It provides information specific to locations within Astana, Kazakhstan.
- **Structured Data Output**: All responses are delivered in a well-defined JSON format.
- **Containerization**: The application is built using Docker and Docker Compose, ensuring consistent and portable deployment.

## 3.0 Technologies

- **FastAPI**: A high-performance web framework for building APIs with Python.
- **Groq**: An AI inference engine.
- **Llama 3 (70B)**: The large language model.
- **Docker & Docker Compose**: For containerization and environment management.
- **Python 3.10+**: The programming language.

## 4.0 Getting Started

Follow these steps to deploy and run the application.

### 4.1 Prerequisites

Ensure that **Docker** and **Docker Compose** are installed and configured on your system.

### 4.2 API Key Configuration

1. Obtain a **Groq API key** by signing up at the [Groq Cloud Console](https://console.groq.com).
2. In your project's root directory, create a file named `.env` and add your API key as follows:

   ```
   GROQ_API_KEY="YOUR_API_KEY_HERE"
   ```

### 4.3 Docker Deployment

To build the Docker image and launch the application containers, execute the following command in your terminal from the project's root directory:

```bash
docker-compose up --build
```

The API will be accessible at:

[http://localhost:8000](http://localhost:8000)

## 5.0 API Usage

The API provides a single endpoint for generating responses.

**Endpoint**: `/chat`

**Method**: `POST`

**Request Body**:

```json
{
  "longitude": 71.44,
  "latitude": 51.16,
  "user_text": "What are some good restaurants in Astana?"
}
```

### 5.1 Testing the API

You can test the functionality of the API using the `curl` command:

```bash
curl -X POST "http://127.0.0.1:8000/chat" \
-H "Content-Type: application/json" \
-d '{
    "longitude": 71.4116,
    "latitude": 51.0898,
    "user_text": "Хан Шатыр"
}'
```
