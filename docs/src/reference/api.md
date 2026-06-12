# API Reference

BaseTypeContracts is intentionally small: loading it registers the Base contracts,
and a couple of helpers let you query them. The full checking, testing and
introspection toolkit lives in
[TypeContracts](https://github.com/el-oso/TypeContracts.jl).

## Module

```@docs
BaseTypeContracts.BaseTypeContracts
```

## The iteration marker

```@docs
BaseTypeContracts.Iterable
```

## Helpers

```@docs
BaseTypeContracts.check
BaseTypeContracts.all_implements
BaseTypeContracts.base_contract_types
```
