---
title: "Homelab 2.5 Ideas"
date: 2025-05-25T20:38:39Z
tags:
  - homelab
  - moving
  - storage
  - networking
categories:
  - personal
  - tech
thumbnailAlt: The "this is fine" dog inside a burning server room.
metaAlignment: left
summary: Jotting down some ideas for improvements to make to my homelab / home network when I move to Puerto Rico.
---

As I've [mentioned elsewhere]( {{< ref "now#moving-to-puerto-rico" >}}), I'll be moving to Puerto Rico soon (3 weeks, at the time of this writing :smile:). As part of the move, I've taken down my server cluster and nas, and will be taking down the route/switch components shortly before we leave. There are some things that I've wanted to update or changes for a while, but either haven't prioritized or didn't want to incur the downtime. I'm going to be down anyway for the move and putting things back incrementally, so this is an opportunity to check off some of those other tasks. Below are some thoughts on things I'd like to consider changing in the new deployment.

## Networking

For quite some time, my networking solution was entirely Ubiquiti UniFi gear. I'd originally really liked the UniFi equipment, but over time had soured on it. A mix of underpowered hardware, end of life software, and being much more comfortable with "enterprise" equipment caused me to look elsewhere when the time came to replace my USG 4. I replaced it with a [Mikrotik Router](https://mikrotik.com/product/ccr2004_16g_2splus)(a manufacturer whose products I'd come to like at work) and had been much happier with the results. Now that I'm moving, I'll complete the replacement and remove the remaining Ubiquiti gear.

### Replace switch

I like my router and have had good results with Mikrotik switches at work. I'll replace the existing switch with a Mikrotik device so that my configurations can be similar (and perhaps shared if I implement Terraform). 12 ports will be occupied by the k8s cluster and nas, several will be consumed by amateur radio gateways and other gizmos, and at least 1 for WiFi so I think I'll need at least a 24 port device. I currently use a lot of PoE devices (mostly APs), but I don't expect to have as much ethernet available in a rented apartment, so I think my main switch won't need this feature. If I do end up with a need for some PoE devices, adding a switch with fewer ports for just this purpose will be more cost-effective than deploying PoE everywhere (my prior strategy :money_mouth_face:). Right now, I'm leaning towards the [CRS326](https://www.newegg.com/mikrotik-crs326-24g-2s-rm/p/0XP-002R-000D0) with 24 gigabit ethernet ports and 2 sfp+.

### Mesh wifi solution

I currently use a mix of Ubiquiti [In-Wall APs](https://store.ui.com/us/en/products/uap-ac-iw) and an [AC Pro](https://store.ui.com/us/en/products/uap-ac-pro) for wireless access points. I plan on moving away from the Ubiquiti equipment and don't expect to be able to run ethernet throughout a rented apartment. A smaller apartment _may_ not need more than 1 AP, but concrete construction can attenuate signals quite a bit and I'd like to keep my options open regarding adding APs. I'm a big fan of Mikrotik's routers and switches, so I'm interested in trying out their wireless capabilities. I'm considering using one or more of [Mikrotik Audience](https://www.newegg.com/p/2RC-061W-00012), but am unsure about the price (and mark-up from MSRP; tariffs?).

The last time I looked at replacing my APs--back when I replaced my USG--TPLink's [Omada](https://www.omadanetworks.com/us/omada-sdn/) wireless products seemed like a good fit for my needs. At the time, I was looking at their in-wall APs, instead of the desktop form-factor (which is still "coming soon"), but the software looks functional, has [OpenAPI documentation](https://omada-northbound-docs.tplinkcloud.com/#/home), and seems like it would integrate fine with the rest of my stack. If the desktop devices are available when I'm building out my permanent wifi solution, this may be the way I go.

### Clean up vlans and subnets

There are a few maintenance tasks around my implementation of vlans, subnets, and DHCP that might be handled while standing things back up.

- Don't route the default vlan.
- Resize subnets, the existing ones are larger than necessary and scattered around the range.
- Performance test. I'm not sure, but the throughtput on the current deployment, especially across vlan, isn't great.

### Implement terraform

I've looked at implementing terraform my [Mikrotik configuration](https://github.com/terraform-routeros/terraform-provider-routeros) before and concluded that the juice wasn't worth the squeeze. That might change with other Mikrotik devices in the mix, though. One of my annoyances with large Mikrotik deployments is that each configuration is disconnected from the others. Over time, my configurations have grown in complexity and would benefit from greater composability. In particular, keeping things like vlan or subnet assignments synced across the devices with a single apply would be quite appealing.

## Storage

### Add additional [disks](https://www.newegg.com/seagate-exos-x24-st24000nm002h-24tb-enterprise-nas-hard-drives-7200-rpm/p/N82E16822185105)

Back in December, I replaced my aging (and power-hungry!) SuperMicro server with a [QNAP TVS-671](https://www.qnap.com/en-us/product/tvs-671). The QNAP has 6 bays; I populated 3 of them with new [Seagate Exos X24](https://www.newegg.com/seagate-exos-x24-st24000nm002h-24tb-enterprise-nas-hard-drives-7200-rpm/p/N82E16822185105) disks, currently configured in a RAID5. I'd intended to eventually populate the remaining bays, adding an additional 4TB usable and a second parity disk. This may be a good time to add that storage.

## Operations

### Github Actions + Wireguard

At one time, I was using [Ansible AWX](https://github.com/ansible-community/awx-operator-helm) to manage the nodes in my k8s cluster and a few other resources. AWX was more resource-intensive in the cluster than I liked, so I removed it and have been looking for a good alternative since then. A CI/CD pipeline for deploying my ansible and terraform configurations is an ideal solution. I might use a local Github agent to run the job, but I also have a wireguard VPN endpoint available. A more convenient solution might be running from a Github hosted runner and connecting via VPN. This would pair nicely with implementing more of network configuration in terraform.

### UPS Batteries

My existing UPS units (a [Tripp Lite SMART1500LCDXL](https://tripplite.eaton.com/support/SMART1500LCDXL) and [expansion](https://tripplite.eaton.com/external-24v-2u-rack-tower-battery-pack-for-select-tripp-lite-ups-systems~BP24V15RT2U)) are ~discontinued~ _fiiine_, but the batteries are dead. I've pulled the batteries out, so I don't have to ship them, so I'll need to replace them with new ones. Seems the [UPS battery](https://tripplite.eaton.com/ups-battery-replacement-for-smart1200lcd-smart1500lcd-smart1500lcdxl-smx1500lcd~RBC1500) is easily replaceable, while the [expansion replacement](https://www.techbatterysolutions.com/tripp-lite-bp24v15rt2u-battery-replacement-kit/) will be a bit more of an adventure. Either way, I'm glad to be able to replace the batteries, rather than having to replace the entire device.

### A new cabinet

Probably something like [this 15U cabinet](https://www.amazon.com/NavePoint-Network-Cabinet-Enclosure-Casters/dp/B01A6JQQHU). I'd like to get something that looks (and sounds :loud*sound::grimacing:) reasonable in our office. The new stack doesn't make \_too much* noise, so I'm hopeful that a fully enclosed cabinet will be nearly silent.
