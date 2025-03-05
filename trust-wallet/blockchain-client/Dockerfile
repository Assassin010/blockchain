FROM golang:1.20 as builder
WORKDIR /app

# Ensure correct architecture
ARG TARGETARCH
RUN echo "Building for architecture: $TARGETARCH"

# Copy Go module files first (for better caching)
COPY go.mod go.sum ./
RUN go mod tidy

COPY . .

# Compile for Linux x86-64 (amd64) for AWS ECS Fargate
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/app .

FROM alpine:latest
WORKDIR /root/

# Install 'file' command to check the binary format
RUN apk add --no-cache file

COPY --from=builder /app/app .
RUN chmod +x /root/app
CMD ["/root/app"]
