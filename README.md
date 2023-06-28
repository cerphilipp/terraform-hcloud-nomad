# terraform-hcloud-nomad

A terraform module to provision a Nomad cluster in Hetzner Cloud using the hcloud terraform provider.

## Prerequisites

Before using this module, ensure you have the following prerequisites:

- Terraform CLI installed on your machine. You can download it from the Terraform website: https://developer.hashicorp.com/terraform/downloads
- An account with Hetzner Cloud and an API token. You can obtain the API token from the Hetzner Cloud Console. Sign up link: https://accounts.hetzner.com/signUp 

## How to use it with the Terraform CLI

Follow these steps to use the `terraform-hcloud-nomad` module with the Terraform CLI:

1. Clone this repository to your local machine:

   ```
   git clone https://github.com/your-username/terraform-hcloud-nomad.git
   ```

2. Change into the cloned repository directory:

   ```
   cd terraform-hcloud-nomad
   ```

3. Initialize the Terraform working directory:

   ```
   terraform init
   ```

4. Set the required input variables:

   Update the `variables.tf` file in the module with your desired configuration. You can provide the necessary values directly in the file or use environment variables or a `terraform.tfvars` file.

5. Review the execution plan:

   ```
   terraform plan
   ```

   This command will show you what changes Terraform will make to your infrastructure.

6. Apply the changes:

   ```
   terraform apply
   ```

   Terraform will now provision the Nomad cluster on Hetzner Cloud based on your configuration.

7. (Optional) Destroy the infrastructure:

   If you want to destroy the Nomad cluster and remove all associated resources, you can run:

   ```
   terraform destroy
   ```

   **Note:** This will permanently delete all resources created by this module. Make sure you have a backup of any important data.

## How to set Terraform input variables

To set the required input variables for the `terraform-hcloud-nomad` module, you have several options:

1. Update the `variables.tf` file:

   You can directly edit the `variables.tf` file in the module and provide the desired values. Make sure to follow the instructions and provide valid input.

2. Environment variables:

   Set the input variables as environment variables before running Terraform commands. The variable names should follow the format `TF_VAR_<variable_name>`. For example:

   ```
   export TF_VAR_hcloud_token="your-hcloud-api-token"
   ```

   Repeat this step for all the required variables.

3. `terraform.tfvars` file:

   Create a `terraform.tfvars` file in the same directory as your Terraform files. In this file, define the input variables and their values. For example:

   ```
   hcloud_token = "your-hcloud-api-token"
   ```

   Terraform will automatically load this file and use the values defined within it.

Choose the method that suits your workflow and provides the most convenience.

## Conclusion

By following the steps outlined above, you can use the `terraform-hcloud-nomad` module to provision a Nomad cluster in Hetzner Cloud with ease. Customize the configuration as needed and leverage the power of Terraform to manage your infrastructure efficiently.