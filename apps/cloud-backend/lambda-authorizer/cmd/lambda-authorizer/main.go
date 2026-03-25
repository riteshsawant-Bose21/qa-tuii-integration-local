package main

import (
	_ "github.com/lib/pq" // Required for PostgreSQL driver registration
	
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/BoseProfessional/lambda-authorizer/internal/authorizer"
)

func main() {
	lambda.Start(authorizer.HandleRequestAuthorizer)
}
