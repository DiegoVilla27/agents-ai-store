---
name: spring-boot-microservices-grpc
description: The ultimate architectural standard for High-Throughput RPC Microservices in Spring Boot 3.x with gRPC, Protocol Buffers (Protobuf), and net.devh grpc-spring-boot-starter.
author: Diego Villanueva
trigger: When building high-performance synchronous microservices in Spring Boot, defining Protobuf contracts, implementing gRPC service stubs, or injecting gRPC client channels.
---

# Enterprise Spring Boot gRPC Microservices Architecture

Synchronous HTTP/REST and JSON introduce heavy serialization overhead. In inter-service enterprise communication, **gRPC over HTTP/2** with binary **Protocol Buffers (Protobuf)** delivers up to 10x lower latency and compile-time contract enforcement.

---

## 1. Protobuf Contract Definition (`account_service.proto`)

```protobuf
// src/main/proto/account_service.proto
syntax = "proto3";

package com.enterprise.grpc.account;
option java_multiple_files = true;
option java_package = "com.enterprise.grpc.account";

service AccountGrpcService {
  rpc GetAccountBalance (AccountBalanceRequest) returns (AccountBalanceResponse);
  rpc StreamTransactions (TransactionFilterRequest) returns (stream TransactionResponse);
}

message AccountBalanceRequest {
  string accountId = 1;
}

message AccountBalanceResponse {
  string accountId = 1;
  double balance = 2;
  string currency = 3;
}

message TransactionFilterRequest {
  string accountId = 1;
  int32 limit = 2;
}

message TransactionResponse {
  string transactionId = 1;
  double amount = 2;
  string timestamp = 3;
}
```

---

## 2. Server Service Implementation (`@GrpcService`)

```xml
<!-- pom.xml -->
<dependency>
    <groupId>net.devh</groupId>
    <artifactId>grpc-server-spring-boot-starter</artifactId>
    <version>3.1.0.RELEASE</version>
</dependency>
```

```java
// service/AccountGrpcServiceImpl.java
package com.enterprise.app.account.service;

import com.enterprise.grpc.account.*;
import io.grpc.Status;
import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;
import net.devh.boot.grpc.server.service.GrpcService;

@GrpcService
@RequiredArgsConstructor
public class AccountGrpcServiceImpl extends AccountGrpcServiceGrpc.AccountGrpcServiceImplBase {

    private final AccountDomainService accountDomainService;

    @Override
    public void getAccountBalance(AccountBalanceRequest request, StreamObserver<AccountBalanceResponse> responseObserver) {
        try {
            var account = accountDomainService.getAccount(request.getAccountId());

            AccountBalanceResponse response = AccountBalanceResponse.newBuilder()
                .setAccountId(account.getId())
                .setBalance(account.getBalance().doubleValue())
                .setCurrency("USD")
                .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (AccountNotFoundException e) {
            responseObserver.onError(Status.NOT_FOUND
                .withDescription(e.getMessage())
                .asRuntimeException());
        }
    }

    @Override
    public void streamTransactions(TransactionFilterRequest request, StreamObserver<TransactionResponse> responseObserver) {
        var transactions = accountDomainService.getRecentTransactions(request.getAccountId(), request.getLimit());

        for (var tx : transactions) {
            TransactionResponse item = TransactionResponse.newBuilder()
                .setTransactionId(tx.getId())
                .setAmount(tx.getAmount().doubleValue())
                .setTimestamp(tx.getTimestamp().toString())
                .build();
            responseObserver.onNext(item);
        }

        responseObserver.onCompleted();
    }
}
```

---

## 3. gRPC Client Stub Injection (`@GrpcClient`)

In consumer microservices (e.g. API Gateway or Payment Service):

```xml
<!-- pom.xml -->
<dependency>
    <groupId>net.devh</groupId>
    <artifactId>grpc-client-spring-boot-starter</artifactId>
    <version>3.1.0.RELEASE</version>
</dependency>
```

```yaml
# application.yml
grpc:
  client:
    account-service:
      address: 'static://localhost:9090'
      negotiationType: plaintext
```

```java
// client/AccountServiceClient.java
package com.enterprise.app.payment.client;

import com.enterprise.grpc.account.AccountBalanceRequest;
import com.enterprise.grpc.account.AccountBalanceResponse;
import com.enterprise.grpc.account.AccountGrpcServiceGrpc;
import net.devh.boot.grpc.client.inject.GrpcClient;
import org.springframework.stereotype.Service;

@Service
public class AccountServiceClient {

    @GrpcClient("account-service")
    private AccountGrpcServiceGrpc.AccountGrpcServiceBlockingStub accountStub;

    public double fetchBalance(String accountId) {
        AccountBalanceRequest request = AccountBalanceRequest.newBuilder()
            .setAccountId(accountId)
            .build();

        AccountBalanceResponse response = accountStub.getAccountBalance(request);
        return response.getBalance();
    }
}
```

---

**Execution Protocol**
1. **Always define Protobuf definitions in a shared Git repository/artifact**: Guarantees contract synchronization.
2. **Translate gRPC error codes (`Status.NOT_FOUND`, `Status.UNAUTHENTICATED`) cleanly**: Avoid throwing generic raw runtime exceptions.
3. **Use client streaming or server streaming for large batches**: Prevents memory spikes.
