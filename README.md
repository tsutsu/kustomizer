# KustomizeR

KustomizeR is a pure-Ruby implementation of [Kustomize](https://kustomize.io/), a
Kubernetes configuration-management tool.

KustomizeR exists to be used by other Ruby tooling, as an alternative to requiring
the user to have the native Go version of Kustomize installed.

## Roadmap

KustomizeR is **not yet feature-complete**, i.e. it does not yet do everything
that Kustomize does. KustomizeR probably won't work for arbitrary
`kustomization.yaml` files.

(KustomizeR *is*, however, in production use; it is being used with
`kustomization.yaml` files matching its current feature set. We wrote Just
Enough Library to solve our own problems :wink:)

Status of `kustomization.yaml` feature support:

* [x] `bases`
* [x] `commonAnnotations`
* [x] `commonLabels`
* [ ] `configMapGenerator` and `secretGenerator`
* [ ] `crds`
* [x] `generators` (see [Extending Kustomize](https://kubectl.docs.kubernetes.io/guides/extending_kustomize/))
* [ ] `generatorOptions`
* [x] `images`
* [ ] `namePrefix` and `nameSuffix`
* [x] `namespace`
* [x] `patches`
* [x] `patchesJson6902`
* [ ] `patchesStrategicMerge`
* [ ] `replicas`
* [x] `resources`
* [ ] `transformers` (see [Extending Kustomize](https://kubectl.docs.kubernetes.io/guides/extending_kustomize/))
* [ ] `vars`

Status of support for other Kustomize features:

* [ ] Resource loading
  * [x] resource-config files on disk
  * [x] `kustomization.yaml` files on disk
  * [x] directories on disk (all resource-config files within)
  * [x] directories on disk (`kustomization.yaml` file within)
  * [ ] files/directories from git repo URLs

* [ ] Automatic name suffixing of generated resources
  * [x] Secrets
  * [x] ConfigMaps

Status of support for "extra" features not supported by Kustomize:

* [ ] `filters` (a plugin-type for dropping resource-configs from output)
* [ ] `rewriters` (a plugin-type for entirely replacing output; takes all
      intermediate resource-config docs as a single input)
* [ ] Built-in plugins:
  * [ ] `SealedSecretGenerator`
  * [ ] `DerivedSecretGenerator`

#### Differences from Kustomize

* KustomizeR is **not yet feature-complete**. (KustomizeR will be bumped to
  version 1.0 once it reaches feature parity with Kustomize.)

* KustomizeR does not support loading Go plugins. Instead, KustomizeR supports
  loading Ruby plugins. See [Plugin Development](#plugin-development) below.

* KustomizeR is modular, and is intended to be loaded and used as a library,
  rather than being spawned as a subprocess. Crucially, the load path for
  plugins is under the caller's control, and so higher-level frameworks can
  inject plugins into a KustomizeR session to suit their needs.

* Some `kustomization.yaml` features have been temporarily extended in
  non-compatible ways:
  * `patchesJson6902`
    * accepts an inline `ops` array
    * accepts lens accessor names in `path` (e.g. `/spec/rules/:all/host`)
    * accepts a `paths` array rather than a single `path`
    * accepts a `gsub` op (works like `replace` but with a regular expression;
      has `pattern` and `replacement` fields)

(Before v1.0, these extensions will be moved to become built-in plugins, to
allow for inter-compatibility with Kustomize, which could support them as
external plugins.)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kustomizer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install kustomizer

## Usage

```ruby
require 'kustomize'
```

### Loading Kustomization documents

You can either load a `kustomization.yaml` file by specifying its path:

```ruby
k = Kustomize.load("./path/to/kustomization.yaml")

# equivalent; discovers the kustomization.yaml within the directory
k = Kustomize.load("./path/to")
```

Or you can load a `Kustomization` document spec directly:

```ruby
k_doc = {
  'apiVersion' => 'kustomize.config.k8s.io/v1beta1',
  'kind' => 'Kustomization',
  # ...
}

k = Kustomization.load(k_doc, source_path: "./path/to/kustomization.yaml")
```

Note the `source_path` keyword parameter. Specifying a `source_path` for an
in-memory Kustomization document is optional, but will usually be necessary, as
the Kustomization document will need an effective path for itself, to use as a
relative navigation prefix for any referenced on-disk resource files/directories.

The `source_path` can be left out if all the resources a Kustomization document
references are either remote or generated.

### Rendering resource-configuration documents

To get the final resource-configurations directly, as an Array of Hashes, call
`KustomizationDocument#emit`:

```ruby
k.emit # => [{'kind' => 'Deployment', ...}, ...]
```

Or, to get a merged YAML multi-document stream suitable for feeding to
`kubectl apply -f`, call `KustomizationDocument#to_yaml_stream`:

```ruby
k.to_yaml_stream # => "---\nkind: Deployment\n..."
```

### Accessing intermediate resources

KustomizeR represents your Kustomization document as a digraph of `Emitter`
instances, a combination of `FileEmitter`s, `DirectoryEmitter`s,
`DocumentEmitter`s, and `PluginEmitter`s. You can think of these as being
arranged akin to an audio VST digraph, where emitters are "plugged into" other
downstream emitters, with the outputs (resource configs) of one emitter becoming
inputs to another.

All `Emitter` types support the following methods:

```ruby
e.input_emitters  # gets the emitters that feed their output into this emitter

e.input_resources # runs the input emitters, gathering their outputs and
                  # caching it as this emitter's input

e.emit            # runs this emitter, producing the output that would be fed
                  # into any downstream emitters
```

A `KustomizationDocument` constructed by `Kustomize.load` is just a regular
`Emitter`; you can use it as the starting point to explore or manipulate the
rest of the `Emitter` graph.

### Sessions

All emitters belong to a `Kustomize::Session`. When you call `Kustomize.load`,
you pass in (or implicitly create) a new `Kustomize::Session`:

```ruby
Kustomize.load("./foo", session: Kustomize::Session.new)
Kustomize.load("./foo") # equivalent to above
```

#### Plugin Load-Paths

The `Kustomize::Session` manages plugin load-paths. By default, it defines a
load-path referencing only the built-in plugins embedded within this gem.

You can create your own subclass of `Kustomize::Session` to define a new
load-path, and pass in an instance of it as the `session` keyword-parameter
to `Kustomize.load`. This custom Session will be inherited by all `Emitter`s
created under the loaded `KustomizeDocument` emitter.

You can also add other features to your `Kustomize::Session` subclass. The
passed-in `Session` is accessible within `Kustomize::Plugin`s as
`this.session`, so it can be useful to pass e.g. a framework context object as
a member of your `Kustomize::Session` subclass, for use by framework-specific
plugins.

#### Plugin Discovery and Loading

The `Kustomize::Session` also holds an instance of `Kustomize::PluginManager`,
which discovers, loads, and caches plugins.

As such, if you're calling `Kustomize.load` a lot, it is recommended to reuse
your `Kustomize::Session`, so that plugins need only be discovered+loaded once.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Plugin Development

TODO

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tsutsu/kustomizer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
