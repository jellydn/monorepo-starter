# Turborepo Monorepo starter

## Using this example

Run the following command:

```sh
git clone https://github.com/jellydn/monorepo-starer
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

### Kubernetes Deployment

This repo includes Kubernetes manifests and scripts to deploy the application to any Kubernetes cluster, whether local, cloud-based, or on-premises.

```
                                     ┌─────────────────────────────────────────────┐
                                     │            Kubernetes Cluster               │
                                     │                                             │
                                     │  ┌─────────────┐       ┌─────────────┐     │
┌─────────────┐    ┌─────────────┐   │  │             │       │             │     │
│             │    │             │   │  │             │       │             │     │
│   Users     ├───►│  Cloudflare ├───┼─►│  Ingress    ├───────►    Web     │     │
│             │    │  (Optional) │   │  │  Controller │       │  Service   │     │
│             │    │             │   │  │             │       │             │     │
└─────────────┘    └─────────────┘   │  │             │       └──────┬──────┘     │
                                     │  │             │              │            │
                                     │  │             │              │            │
                                     │  │             │       ┌──────▼──────┐     │
                                     │  │             │       │             │     │
                                     │  │             │       │    API      │     │
                                     │  │             ├───────►  Service    │     │
                                     │  │             │       │             │     │
                                     │  └─────────────┘       └─────────────┘     │
                                     │                                             │
                                     └─────────────────────────────────────────────┘
```

#### Local Development with Kubernetes

To set up a local Kubernetes environment:

```sh
# Set up a local Kubernetes cluster with kind
./k8s/setup-local.sh

# Deploy the application to the local cluster
REGISTRY_URL=localhost:5000 ./k8s/deploy.sh
```

#### Production Deployment with Cloudflare

For production deployment with Cloudflare as a proxy:

```sh
# Deploy with Cloudflare integration
REGISTRY_URL=your-registry.example.com CONTEXT=your-cluster-context USE_CLOUDFLARE=true DOMAIN=yourdomain.com ./k8s/deploy.sh
```

For more details, see the [Kubernetes README](./k8s/README.md).

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
