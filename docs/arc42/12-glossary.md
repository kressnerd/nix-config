# 12. Glossary

<!-- Domain and technical terms used in this project. Entries are alphabetically
     ordered. Use the same terms consistently throughout all documentation. -->

| Term | Definition |
|---|---|
| Identity declaration | A host's statement of which identity material that device holds (`myHome.ssh`), from which the connection entries and the workspace identity configuration are rendered. |
| Identity file | The private key file a device presents to authenticate to a remote Git host. |
| Identity material | The private keys a device holds for the identities it uses; a device declares it, and a connection entry is rendered only where the device declares the material for that identity. |
| Personal identity | The device owner's own identity on a device: its private key and the connection and workspace surfaces derived from that key. |
| Private workspace | The workspace directory whose Git operations use the device's personal identity, selected by the host's include rule. |
| Work identity | An employer or client identity, with its own key and connection entry, declared only on a device that holds that identity's material. |
