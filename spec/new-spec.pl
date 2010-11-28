## ------------------------------------------------------------------
## Reference Schema
## ------------------------------------------------------------------

my $ref = {
    id          => "schema/core/ref",
    title       => "Reference Schema",
    description => "This is the 'reference' type for JSON",
    type        => "object",
    properties  => {
        '$ref'  => { type => "string" }
    }
};


## ------------------------------------------------------------------
## Core Schema Types
## ------------------------------------------------------------------

my $any = {
    id          => "schema/types/any",
    title       => "Any type Schema",
    description => "This is a schema for the 'any' type",
    type        => "object",
    properties  => {
        type => { type => "string", enum => [ "any" ] }
    },
    additionalProperties => {
        id          => { type => "string" }, ## might need a pattern for a URI here
        title       => { type => "string" },
        description => { type => "string" },
        extends     => { type => "object" }  ## a ref is just a specially processed object
                                             ## and a schema is just an object
        ## The Hyper Schema ...
        links => {
            type        => "array",
            items       => { '$ref' => "schema/hyper/link" },
            uniqueItems => "true"
        }
    }
};

my $null = {
    id          => "schema/types/null",
    title       => "Null type Schema",
    description => "This is a schema for the 'null' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/any" },
    properties  => {
        type => { type => "string", enum => [ "null" ] }
    }
};

my $boolean = {
    id          => "schema/types/boolean",
    title       => "Boolean type Schema",
    description => "This is a schema for the 'boolean' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/any" },
    properties  => {
        type => { type => "string", enum => [ "boolean" ] }
    }
};

my $number = {
    id          => "schema/types/number",
    title       => "Number type Schema",
    description => "This is a schema for the 'number' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/any" },
    properties  => {
        type => { type => "string", enum => [ "number" ] },
    },
    additionalProperties => {
        minimum          => { type => "number" },
        maximum          => { type => "number" },
        exclusiveMinimum => { type => "boolean" },
        exclusiveMaximum => { type => "boolean" },
        enum             => {
            type        => "array",
            items       => { type => "number" },
            uniqueItems => "true"
        }
    }
};

my $integer = {
    id          => "schema/types/integer",
    title       => "Integer type Schema",
    description => "This is a schema for the 'integer' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/number" },
    properties  => {
        type => { type => "string", enum => [ "integer" ] },
    },
    additionalProperties => {
        minimum => { type => "integer" },
        maximum => { type => "integer" }
        enum    => {
            type        => "array",
            items       => { type => "integer" },
            uniqueItems => "true"
        },
    }
};

my $string = {
    id          => "schema/types/string",
    title       => "String type Schema",
    description => "This is a schema for the 'string' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/any" },
    properties  => {
        type => { type => "string", enum => [ "string" ] },
    },
    additionalProperties => {
        minLength => { type => "number" },
        maxLength => { type => "number" },
        pattern   => { type => "string" },
        enum      => {
            type        => "array",
            items       => { type => "string" },
            uniqueItems => "true"
        },
    }
};

my $array = {
    id          => "schema/types/array",
    title       => "Array type Schema",
    description => "This is a schema for the 'array' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/any" },
    properties  => {
        type => { type => "string", enum => [ "array" ] },
    },
    additionalProperties => {
        items       => { type => "object" },
        minItems    => { type => "integer" },
        maxItems    => { type => "integer" },
        uniqueItems => { type => "boolean" }
    }
};

my $object = {
    id          => "schema/types/object",
    title       => "Object type Schema",
    description => "This is a schema for the 'object' type",
    type        => "object",
    extends     => { '$ref' => "schema/types/any" },
    properties  => {
        type => { type => "string", enum => [ "object" ] },
    },
    additionalProperties => {
        properties           => { type => "object" },
        additionalProperties => { type => "object" }
    }
};

## ------------------------------------------------------------------
## Hyper Schema
## ------------------------------------------------------------------

my $link = {
    id          => "schema/hyper/link",
    title       => "Link Hyper Schema",
    description => "This is the 'link' type for the hyper schema",
    type        => "object",
    properties  => {
        rel  => { type => "string" },
        href => { type => "string" },
    },
    additionalProperties => {
        # schema of the resource linked to ...
        targetSchema => { type => "object" },
        # submission link properties ...
        schema       => { type => "object" },
        method       => { type => "string", enum => [ "GET", "POST", "PUT", "DELETE" ] },
        # additional data to support Service discoverability
        title        => { type => "string" },
        description  => { type => "string" },
        metadata     => { type => "object" }
    }
};

## ------------------------------------------------------------------




