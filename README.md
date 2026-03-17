# Grade Classifier API

Classify grade based on score.

## Endpoint

### GET `/classify`

**Parameters:**
- `score` (required): Score (0-100)

**Example Request:**
```
http://localhost:3023/classify?score=85
```

**Example Response:**
```json
{
  "score": 85,
  "grade": "B",
  "category": "Good"
}
```

**การทำTF**
 ```
 1 git clone https://github.com/Teerawatgg/devops68-grade-classifier-Q2.git
 2 สร้าง terraform สร้าง ไฟล์ main.tf outputs.tf providers.tf variables.tf
 3 ติ้งตั้ง azure cli  az version  
 4 az login   
 5 az account set --subscription "Azure Subscription ID"   
 6 terraform init  
 7 terraform plan  
 8 terraform apply -var-file="terraform.tfvars"
 http://4.193.231.104:3023/classify?score=85

 ```
