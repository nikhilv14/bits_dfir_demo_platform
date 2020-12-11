terraform {
  backend "gcs" {
    credentials = "./bits-dfir.json"
    bucket      = "bits_tf_state"
    prefix      = "terraform/state"
  }
}