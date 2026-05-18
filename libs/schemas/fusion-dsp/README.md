JSON Schemas for Fusion Data Formats
====================================

This directory is the monorepo home for the shared Fusion DSP exchange
schemas. These files were imported from the former standalone
`fusion-schemas` repository so `fusion-server`, `fusion-launcher`, and related
tools can evolve against the same checked-in contract.

The schemas in this repository specify the JSON formats used to exchange data
between various components in the Fusion ecosystem.  They should be used to
validate the outputs of any software (or manual process) that generates JSON
data for use with Fusion.

- `interface-definition.json`: Definitions of properties, terminals,
    parameters, and telemetry common to DSP algorithms and firmware modules.
- `algorithm-definition.json`: Definitions of DSP algorithms and their
    interfaces.
- `circuit-definition.json`: Definitions of DSP circuits, which are collections
    of signal processing blocks used to modularize designs.
- `static-configuration.json`: Definitions of static DSP configurations, which
    fully specify all of the signal processing to be run.


Using the Schemas
-----------------

The Python package `check-jsonschema` is one of the available command-line
tools for validating JSON data against a schema.

For example, to validate Fusion DSP's `algorithm-definitions.json` against
this repo's `algorithm-definition.json`, run:

~~~
check-jsonschema --schemafile algorithm-definition.json algorithm-definitions.json
~~~

This can also be used to test that any of the schemas in this repo are valid
JSON schemas:

~~~
check-jsonschema --check-metaschema interface-definition.json
~~~
