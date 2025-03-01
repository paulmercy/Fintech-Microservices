# Fintech Microservices Application

This project implements a set of microservices for a Fintech application, including user account management, transaction processing, and potentially other financial services. The application is designed to be deployed on Kubernetes using Docker containers and orchestrated with Helm.

## System Architecture Diagram
<object type="image/svg+xml" data="architecture/architecture-diagram.svg" style="width: 100%; max-width: 800px"></object>

## Architecture
The application consists of the following microservices:

-   **User Service:** Manages user accounts, including creation, retrieval, and balance updates.
-   **Transaction Service:** Handles financial transactions, interacting with the User Service to update balances.
-   **YugabyteDB:** A distributed SQL database used for persistent data storage.
-   **Open Policy Agent (OPA):** An open-source policy engine for access control and authorization.
-   **APISIX API Gateway:** A dynamic API gateway for routing and managing external access to the services.

## Prerequisites

Before you begin, ensure you have the following installed:

-   [Docker](https://www.docker.com/)
-   [kubectl](https://kubernetes.io/docs/tasks/tools/)
-   [Helm](https://helm.sh/docs/)
-   [Minikube](https://minikube.sigs.k8s.io/docs/) (for local development)
-   Python 3.6+
-   pip

## Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2.  **Install dependencies:**

    ```bash
    make install-dependencies
    ```

3.  **Start Minikube (optional, for local development):**

    ```bash
    make start-minikube
    ```

4.  **Build Docker images:**

    ```bash
    make build-images
    ```

5.  **Load Docker images into Minikube (optional, for local development):**

    ```bash
    make load-images-minikube
    ```

## Deployment

You can deploy the application using either Kubernetes manifests or Helm.

### Using Kubernetes Manifests

1.  **Create the Kubernetes namespace:**

    ```bash
    make create-namespace
    ```

2.  **Deploy the components:**

    ```bash
    make deploy-all
    ```

### Using Helm

1.  **Create the Kubernetes namespace:**

    ```bash
    make create-namespace
    ```

2.  **Deploy the application using Helm:**

    ```bash
    make deploy-helm
    ```

## Configuration

The application is configured using environment variables and Kubernetes ConfigMaps and Secrets.

-   **Database Configuration:** Database connection details are stored in a Kubernetes Secret named `db-credentials` and referenced in the microservice deployments.
-   **Service URLs:** The URLs for inter-service communication are defined in a ConfigMap named `fintech-config`.

## Accessing the Application

After deployment, you can access the application through the APISIX API Gateway.

1.  **Set up port forwarding (for local development):**

    ```bash
    make port-forward
    ```

2.  **Access the services:**

    -   User Service: `http://localhost:8080/api/users`
    -   Transaction Service: `http://localhost:8080/api/transactions`

## Testing

The Makefile includes commands for testing the services:

-   **Create a test user:**

    ```bash
    make test-create-user
    ```

-   **Create a test transaction:**

    ```bash
    make test-create-transaction
    ```

## Monitoring and Logging

-   **View logs for User Service:**

    ```bash
    make logs-user-service
    ```

-   **View logs for Transaction Service:**

    ```bash
    make logs-transaction-service
    ```

## Cleanup

To remove all deployed resources:

```bash
make cleanup