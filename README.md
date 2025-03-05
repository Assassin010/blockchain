# Blockchain Client

This Go application interacts with the Polygon RPC API to fetch block numbers and details. It is containerized using Docker and deployable to AWS ECS Fargate.

```
/blockchain-client
│── main.go                 # Entry point of the application
│── handlers.go             # API handlers for fetching block data
│── rpc_client.go           # Functions for interacting with the Polygon RPC
│── rpc_client_test.go      # Unit tests for the RPC client
│── Dockerfile              # Dockerfile for containerization
│── go.mod                  # Go module definition
│── go.sum                  # Go dependencies checksum
│── /terraform              # Terraform folder for AWS ECS Fargate deployment
│   ├── main.tf             # Defines ECS Fargate infrastructure
│   ├── variables.tf        # Contains input variables
│   ├── outputs.tf          # Defines outputs for infrastructure
│── README.md               # Documentation
```


# File Explanations:

main.go - Sets up the HTTP server and routes.
handlers.go - Contains HTTP handler functions (getBlockNumber, getBlockByNumber).
rpc_client.go - Implements sendRPCRequest() to communicate with the Polygon RPC.
rpc_client_test.go - Unit tests for the RPC client functions.
Dockerfile - Defines how to containerize the Go application.
terraform/main.tf - AWS ECS Fargate configuration for deploying the application.
terraform/variables.tf - Defines Terraform input variables.
terraform/outputs.tf - Specifies Terraform outputs.
README.md - Documentation including usage instructions and future improvements.

```
          +-----------------+
          |   main.go       |  🏠 Entry Point
          +-----------------+
                  |
                  v
          +-----------------+
          |  handlers.go     |  📡 API Handlers (Exposes /blockNumber & /blockByNumber)
          +-----------------+
                  |
                  v
          +-----------------+
          | rpc_client.go   |  🔗 Sends Requests to Polygon RPC
          +-----------------+
                  |
                  v
        +----------------------+
        | https://polygon-rpc.com | 🌐 External API
        +----------------------+

          +----------------------+
          | rpc_client_test.go   |  ✅ Unit Tests (Mocks RPC)
          +----------------------+
```

## Unit test documentation in a deployed ECS environment**,
## Mocks API requests and validates responses.

## **✅ 1. Test the Running API on ECS**
Once your application is running on **AWS ECS**, use **cURL or AWS CLI** to test it.

### **Find ECS Public IP or Load Balancer**
#### **If your ECS Task has a Public IP:**
1. **Go to AWS Console** → ECS → Clusters → `blockchain-cluster`
2. Click on **Tasks** → Click on the **Running Task**.
3. Look for **Public IP** under **Network Configuration**.

Or use the AWS CLI:
```sh
aws ecs describe-tasks --region eu-west-1 --cluster blockchain-cluster \
    --tasks $(aws ecs list-tasks --cluster blockchain-cluster --query "taskArns[]" --output text) \
    --query "tasks[].attachments[].details[?name=='networkInterfaceId'].value[]" --output text"
```

Then, get the Public IP:
```sh
aws ec2 describe-network-interfaces --network-interface-ids <NETWORK_INTERFACE_ID> \
    --query "NetworkInterfaces[].Association.PublicIp" --output text
```

#### **If your ECS Service uses an ALB:**
Get the ALB DNS Name:
```sh
aws elb describe-load-balancers --region eu-west-1 --query "LoadBalancerDescriptions[].DNSName"
```

---

### **✅ 2. Run API Tests via cURL**
#### **Check Block Number**
```sh
curl http://<ECS_PUBLIC_IP>:8080/blockNumber
```
Expected Response:
```json
"0x134e82a"
```

#### **Check Block by Number**
```sh
curl "http://<ECS_PUBLIC_IP>:8080/blockByNumber?block=0x134e82a"
```
Expected Response:
```json
{
  "number": "0x134e82a",
  "hash": "0x...",
  "parentHash": "0x...",
  "transactions": [...]
}
```

If using an **ALB**, replace `<ECS_PUBLIC_IP>` with `<ALB_DNS_NAME>`.

---

## **✅ 3. Run Tests Locally Using AWS CLI**
If your application is **not reachable**, you can test it **inside an ECS task**.

#### **Run a Command Inside ECS Task**
```sh
aws ecs execute-command --cluster blockchain-cluster \
    --task $(aws ecs list-tasks --region eu-west-1 --cluster blockchain-cluster --query "taskArns[]" --output text) \
    --container blockchain-client \
    --command "curl http://localhost:8080/blockNumber" \
    --interactive
```

Expected response:
```json
"0x134e82a"
```

---

## **✅ 4. Run Tests Locally Before Deployment**
If you want to **test locally before deploying**, run:

```sh
docker run --rm -p 8080:8080 blockchain-client
```

Then, in another terminal:
```sh
curl http://localhost:8080/blockNumber
```

## **🚀 Summary**
- ✅ **Find ECS Public IP or ALB DNS** (`aws ecs describe-tasks`)
- ✅ **Test API using `curl`**
- ✅ **Use AWS CLI to test inside ECS Task (`aws ecs execute-command`)**
- ✅ **Test locally before deployment using Docker**
- 

## Future Improvements for Production Readiness

1. **Logging & Monitoring**: Use structured logging with log aggregation (e.g., AWS CloudWatch, Loki).
2. **Security**: Implement authentication for API requests.
3. **CI/CD Pipeline**: Automate builds and deployments with GitHub Actions
4. **Scalability**: Use auto-scaling in AWS ECS Fargate.
5. **Configuration Management**: Use environment variables for sensitive information.
6. **Health Checks**: Add `/health` endpoint to monitor the application's status.
7. **Load Balancer**: Deploy behind an AWS ALB for better traffic handling.
