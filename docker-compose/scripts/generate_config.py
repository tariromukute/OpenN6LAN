import yaml

def generate_far(farID, teid, interface):
    if interface == "SGiLAN":
        return {
            "farID": farID,
            "applyAction": "Forward",
            "forwardingParameters": {
                "destinationInterface": "SGiLAN",
                "networkInstance": "core.oai.org"
            }
        }
    elif interface == "Access":
        return {
            "farID": farID,
            "applyAction": "Forward",
            "forwardingParameters": {
                "destinationInterface": "Access",
                "networkInstance": "access.oai.org",
                "outerHeaderCreation": {
                    "desc": "OUTER_HEADER_CREATION_GTPU_UDP_IPV4",
                    "teid": teid,
                    "ip": "192.168.71.130"
                }
            }
        }
    return None
   
def generate_config(num_ues):
    """Generates a YAML configuration file for a given number of UEs.

    Args:
        num_ues: The number of UEs to include in the configuration.

    Returns:
        A YAML-formatted string representing the configuration.
    """

    array = []
    for ue_id in range(1, num_ues + 1):
        config = {
            "seid": ue_id,
            "pdrs": [],
            "fars": []
        }
        pdr_id = ue_id * 2 - 1
        pdr = {
            "pdrID": pdr_id,
            "precedence": 0,
            "pdi": {
                "sourceInterface": "Access",
                "networkInstance": "access.oai.org",
                "localFTEID": {
                    "teid": ue_id,
                    "ip4": "192.168.71.134"
                },
                "ueIPAddress": {
                    "isDestination": False,
                    "ip4": f"16.0.0.{ue_id}"
                }
            },
            "outerHeaderRemoval": "OUTER_HEADER_GTPU_UDP_IPV4",
            "farID": pdr_id
        }
        config["pdrs"].append(pdr)
        far = generate_far(pdr_id, ue_id, "SGiLAN")
        config["fars"].append(far)

        pdr_id += 1
        pdr = {
            "pdrID": pdr_id,
            "precedence": 0,
            "pdi": {
                "sourceInterface": "SGiLAN",
                "networkInstance": "core.oai.org",
                "ueIPAddress": {
                    "isDestination": True,
                    "ip4": f"16.0.0.{ue_id}"
                }
            },
            "farID": pdr_id
        }
        config["pdrs"].append(pdr)
        far = generate_far(pdr_id, ue_id, "Access")
        config["fars"].append(far)

        array.append(config)

    return yaml.dump(array, indent=2)

if __name__ == "__main__":
    num_ues = 50  # Replace with the desired number of UEs
    config = generate_config(num_ues)
    with open("config.yaml", "w") as f:
        f.write(config)