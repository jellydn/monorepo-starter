# Monorepo Starter

A modern monorepo starter template with web frontend, API backend, and PostgreSQL database.

## Features

- 🚀 **Modern Stack**: React/NextJs, Express.js, PostgreSQL
- 📦 **Monorepo Structure**: Using pnpm workspaces
- 🐳 **Docker Support**: Development and production ready
- ☸️ **Kubernetes Support**: Production-grade deployment
- 🔄 **TypeScript**: Full type safety
- 📝 **Prisma**: Type-safe database access
- 🧪 **Testing**: Vitest for unit and integration tests

## Project Structure

```
.
├── apps/
│   ├── web/          # React frontend
│   └── api/          # Express.js backend
├── packages/         # Shared packages
│   ├── auth/         # Authentication package
│   ├── db/           # Database package
│   ├── logger/       # Logging package
│   ├── ui/           # UI components
│   └── typescript-config/ # TypeScript configuration
├── docs/             # Documentation
│   ├── architecture.md # Architecture documentation
│   └── kubernetes.md # Kubernetes documentation
├── kubernetes/       # Kubernetes configurations
└── docker-compose.yml
```

## Getting Started

### Prerequisites

- Node.js 22+
- pnpm
- Docker and Docker Compose
- Kubernetes (for production deployment)

### Development

1. Install dependencies:

```bash
pnpm install
```

2. Start development environment:

```bash
docker-compose up -d
```

3. Start development servers:

```bash
# Terminal 1 - Web
pnpm --filter web dev

# Terminal 2 - API
pnpm --filter api dev
```

The application will be available at:

- Web: http://localhost:3000
- API: http://localhost:3001
- Database: localhost:5432

### Production Deployment

#### Docker Compose

```bash
docker-compose -f docker-compose.prod.yml up -d
```

#### Kubernetes

See [Kubernetes Deployment Guide](docs/k8s.md) for detailed instructions.

## Architecture

The application consists of three main components:

1. **Web Frontend**: React application with Tailwind CSS
2. **API Backend**: Express.js server with Prisma ORM
3. **Database**: PostgreSQL for data persistence

See [Architecture Documentation](docs/architecture.md) for detailed diagrams and explanations.

## Development

### Available Scripts

```bash
# Install dependencies
pnpm install

# Start development servers
pnpm dev

# Build all packages and applications
pnpm build

# Run tests
pnpm test

# Lint code
pnpm lint

# Type check
pnpm typecheck
```

### Database Management

```bash
# Generate Prisma client
pnpm --filter api prisma generate

# Run database migrations
pnpm --filter api prisma migrate dev

# Reset database
pnpm --filter api prisma migrate reset
```

## Testing

```bash
# Run all tests
pnpm test

# Run tests for specific package
pnpm --filter @repo/api test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Using this template

Run the following command:

```sh
git clone https://github.com/jellydn/monorepo-starter
```

or

```sh
pnpm dlx create-turbo@latest -m pnpm -e https://github.com/jellydn/monorepo-starter YOUR_PROJECT
```

## What's inside?

This Turborepo includes the following:

### Apps and Packages

- `web`: a [Next.js](https://nextjs.org/) app
- `api`: an [Express](https://expressjs.com/) server
- `@repo/ui`: a React component library
- `@repo/typescript-config`: tsconfig.json's used throughout the monorepo

Each package/app is 100% [TypeScript](https://www.typescriptlang.org/).

### Docker

This repo is configured to be built with Docker, and Docker compose. To build all apps in this repo:

```sh
# Install dependencies
pnpm install

# Create a network, which allows containers to communicate
# with each other, by using their container name as a hostname
docker network create app_network

# Build prod using new BuildKit engine
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose -f docker-compose.yml build

# Start prod in detached mode
docker-compose -f docker-compose.yml up -d
```

Open http://localhost:3000.

To shutdown all runnin containers:

```sh
# Stop all running containers
docker kill $(docker ps -q) && docker rm $(docker ps -a -q)
```

### GitHub Container Registry (GHCR)

This repo is configured to publish Docker images to GitHub Container Registry (GHCR). The images are automatically built and published when you push to the `main` branch or create a new tag.

#### CI/CD Workflow

The GitHub Actions workflow builds and publishes Docker images in parallel for faster execution:

- The web and API images are built simultaneously in separate jobs
- Each build supports multi-architecture images
- A summary job runs after all builds are complete to report the status

#### Multi-Architecture Support

The Docker images are built for multiple architectures:

- `linux/amd64` - For Intel/AMD processors (standard x86_64 architecture)
- `linux/arm64` - For ARM processors (Apple Silicon M1/M2/M3, AWS Graviton, etc.)

This ensures that the images can run on various platforms without compatibility issues.

#### Using GHCR Images Locally

Instead of building Docker images locally, you can use the pre-built images from GHCR:

1. Create a `.env` file based on the `.env.example` template:

```sh
cp .env.example .env
```

2. Edit the `.env` file with your GitHub username and repository name:

```
GHCR_USERNAME=your-github-username
GHCR_REPO=monorepo-starter
GHCR_REGISTRY=ghcr.io
GHCR_TAG=latest
```

3. Log in to GitHub Container Registry:

```sh
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

4. Start the containers using the pre-built images:

```sh
docker-compose up -d
```

#### Helper Script

For convenience, a helper script is provided to simplify working with GHCR images:

```sh
./use-ghcr-images.sh
```

This interactive script provides the following options:

- Pull and use GHCR images with docker-compose
- Pull and use GHCR images with Kubernetes
- Check available tags for images
- Login to GitHub Container Registry

The script will automatically create a `.env` file with default values if one doesn't exist.

#### Available Tags

The following tags are available for the Docker images:

- `latest`: The latest build from the `main` branch
- `main`: The latest build from the `main` branch
- `vX.Y.Z`: Specific version tags (e.g., `v1.0.0`)
- `sha-XXXXXXX`: Specific commit SHA

### Kubernetes Deployment

This repo includes Kubernetes manifests and scripts to deploy the application to any Kubernetes cluster, whether local, cloud-based, or on-premises.

#### Kubernetes Templates

This repository offers two Kubernetes deployment templates:

##### 1. Basic Template (For Beginners)

If you're new to Kubernetes, you can use the basic template available at [basic-k8s branch](https://github.com/jellydn/monorepo-starter/tree/basic-k8s). This template provides a simpler structure with all configuration in a single `k8s` directory.

```sh
# Clone the repository with the basic-k8s branch
git clone -b basic-k8s https://github.com/jellydn/monorepo-starter.git
cd monorepo-starter

# Set up a local Kubernetes cluster with kind
./k8s/setup-local.sh

# Deploy the application to the local cluster
./k8s/deploy.sh
```

##### 2. Advanced Template (Main Branch)

The main branch uses a more sophisticated structure with Kustomize overlays for different environments. This approach is better suited for production deployments and multi-environment setups.

#### Local Development with Kubernetes

To set up a local Kubernetes environment:

```sh
# Set up a local Kubernetes cluster with kind
./kubernetes/scripts/setup-local.sh

# Deploy the application to the local cluster
./kubernetes/scripts/deploy-local.sh
```

#### Production Deployment with Cloudflare

For production deployment with Cloudflare as a proxy:

```sh
# Deploy with Cloudflare integration
REGISTRY_URL=your-registry.example.com \
CONTEXT=your-production-context \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./kubernetes/scripts/deploy-production.sh
```

For more details, see the [Kubernetes Documentation](./docs/kubernetes.md).

### Remote Caching

> [!TIP]
> Vercel Remote Cache is free for all plans. Get started today at [vercel.com](https://vercel.com/signup?/signup?utm_source=remote-cache-sdk&utm_campaign=free_remote_cache).

This example includes optional remote caching. In the Dockerfiles of the apps, uncomment the build arguments for `TURBO_TEAM` and `TURBO_TOKEN`. Then, pass these build arguments to your Docker build.

You can test this behavior using a command like:

`docker build -f apps/web/Dockerfile . --build-arg TURBO_TEAM="your-team-name" --build-arg TURBO_TOKEN="your-token" --no-cache`

### Utilities

This Turborepo has some additional tools already setup for you:

- [TypeScript](https://www.typescriptlang.org/) for static type checking
- [Biome](https://biomejs.dev) for format, lint, and more in a fraction of a second.
