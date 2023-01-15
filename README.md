# pwsh-dp_connectivity
# Requirements:
The server where this script executes must have access to the wmi of the remote server.

Typically, access rights and firewall rules (tcp135, tcp445, rpc high ports range) is required.

# Sample output:
Ok
```sh
DCW01.FABRIKAM.LOCAL - DNS Query = pass
DCW01.FABRIKAM.LOCAL - TCP 135 = pass
DCW01.FABRIKAM.LOCAL - TCP 445 = pass
DCW01.FABRIKAM.LOCAL - Remote WMI = pass
```

Not good
```sh
DCW02.FABRIKAM.LOCAL - DNS Query = fail
```
