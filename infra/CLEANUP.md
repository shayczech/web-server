# AWS cleanup and cost control

Use this when you see extra EC2 instances (e.g. 4 running + 4 terminated) or want to reduce cost.

## Why you might see 8 instances (4 running, 4 terminated)

- **Terminated** – AWS lists recently terminated instances for a while (often ~1 hour). They do **not** incur charges; they disappear from the list automatically.
- **Extra running** – Can happen when:
  1. **Instance refresh** – Pipeline starts a refresh, new instances come up, then the job fails or times out before old ones are terminated. Re-running the pipeline can add more instances.
  2. **Orphaned ASG or instances** – An old Auto Scaling Group (or standalone EC2) from a previous setup still exists and is not in Terraform.
  3. **Manual scaling** – ASG was scaled up in the console and never scaled back.

Terraform only manages **one** ASG: `web-server-asg` (or `"${var.server_name}-asg"`). Any other ASGs or standalone EC2s are outside Terraform and must be cleaned up manually.

## One-time cleanup (do this now)

### 1. Align Terraform with reality

```bash
cd infra
terraform init
terraform plan
```

- If plan shows **no changes** and you still have 4 running instances, the extras are either in the same ASG (scale-in didn’t run) or in another ASG/standalone.
- If plan shows **desired_capacity** change (e.g. 2 → 1), run `terraform apply` so the ASG scales in to the desired count.

### 2. Scale in the managed ASG (if it has too many instances)

Either:

- **Via Terraform:** Set `desired_capacity = 1` in `asg.tf` (already set in this repo), then:

  ```bash
  terraform apply
  ```

  The ASG will terminate excess instances until only 1 is running.

Or:

- **Via Console:** EC2 → Auto Scaling Groups → select `web-server-asg` → Edit → set Desired capacity to 1 → Save.

### 3. Find and remove orphaned resources

1. **EC2 → Instances**
   - For each **Running** instance, check **Auto Scaling Group**. If it says `web-server-asg`, it’s managed by Terraform; scaling the ASG to 1 will remove extras.
   - If an instance has **no** ASG or a different ASG name (e.g. an old name), it’s orphaned. Terminate it from the console (or remove it from the other ASG, then terminate).

2. **EC2 → Auto Scaling Groups**
   - You should see only **one** ASG: `web-server-asg`. If you see another (e.g. `web-server` or an older name), that’s orphaned. Edit it to set desired/min to 0, wait for instances to terminate, then delete the ASG.

3. **Launch templates**
   - EC2 → Launch Templates. Terraform uses names like `web-server-lt-*` with `create_before_destroy`, so old versions may remain. They don’t run or cost money; you can delete old versions from the console if you want to tidy up.

### 4. Terminated instances

No action needed. They stop appearing in the list after a short time and are not billed.

## Ongoing: avoid accumulation

- **Single source of truth** – Only use Terraform (or the GitHub Actions pipeline that runs `terraform apply`) to change the ASG. Avoid manually changing desired capacity in the console unless you then run `terraform apply` so state matches.
- **Desired capacity** – This repo sets `desired_capacity = 1` so you normally pay for one instance. Change it in `asg.tf` if you want 2 for HA.
- **Instance refresh** – If the pipeline times out during an instance refresh, you can be left with extra running instances. After fixing the pipeline, run `terraform apply` once; Terraform will set the ASG back to desired capacity and the ASG will scale in.

## Quick reference

| Resource            | Managed by Terraform | Name / pattern        |
|---------------------|----------------------|------------------------|
| Auto Scaling Group  | Yes                  | `web-server-asg`      |
| Launch template     | Yes                  | `web-server-lt-*`     |
| Running EC2 in ASG  | Yes (via ASG)        | Name: `web-server-asg-instance` |
| Other ASGs / EC2    | No                   | Delete or terminate manually   |
