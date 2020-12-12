module "gke" {
  #source                     = "terraform-google-modules/kubernetes-engine/google"
  source                     = "github.com/terraform-google-modules/terraform-google-kubernetes-engine"
  project_id                 = var.project_id
  region                     = var.region
  zones                      = var.zones
  name                       = var.name
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  #kubernetes_dashboard       = true
  network_policy             = true
  #check_env.sh not a win32 application fix#
  skip_provisioners          = true

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = var.machine_type
      min_count          = var.min_count
      max_count          = var.max_count
      disk_size_gb       = var.disk_size_gb
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = var.service_account
      preemptible        = false
      initial_node_count = var.initial_node_count
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

#components for outside GKE clusters
resource "random_id" "instance_id" {
 byte_length = 8
}

// A single Compute Engine instance
resource "google_compute_instance" "elastic" {
 name         = "elastic-vm-${random_id.instance_id.hex}"
 machine_type = var.machine_type
 zone         = var.zones[0]

 boot_disk {
   initialize_params {
     image = "ubuntu-os-cloud/ubuntu-1804-bionic-v20201211a"
   }
 }

// Make sure elastic pre-requisites are installed on all new instances for later steps
 metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync openjdk-8-jre"
 metadata = {
   ssh-keys = "nikhil:${file("~/.ssh/github_n14aug.pub")}"
 }


 network_interface {
   network = "default"
   access_config {
    
   }
 }
}

// A single Compute Engine instance
resource "google_compute_instance" "hive" {
 name         = "hive-vm-${random_id.instance_id.hex}"
 machine_type = var.machine_type
 zone         = var.zones[0]

 boot_disk {
   initialize_params {
     image = "ubuntu-os-cloud/ubuntu-1804-bionic-v20201211a"
   }
 }

// Make sure elastic pre-requisites are installed on all new instances for later steps
 metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync openjdk-8-jre"
 metadata = {
   ssh-keys = "nikhil:${file("~/.ssh/github_n14aug.pub")}"
 }
 network_interface {
   network = "default"
   access_config {
   }
 }
}

output "elastic_ip" {
value = google_compute_instance.elastic.network_interface.0.access_config.0.nat_ip
}

output "hive_ip" {
 value = google_compute_instance.hive.network_interface.0.access_config.0.nat_ip
}
