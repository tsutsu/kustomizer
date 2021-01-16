# KustomizeR

KustomizeR is a pure-Ruby implementation of [Kustomize](https://kustomize.io/), a
Kubernetes configuration-management tool.

KustomizeR exists to be used by other Ruby tooling, as an alternative to requiring
the user to have the native Go version of Kustomize installed.

## Roadmap

KustomizeR is **not yet feature-complete**, i.e. it does not yet do everything
that Kustomize does.

Status of `kustomization.yaml` support:

* [x] `bases`
* [ ] `commonAnnotations`
* [ ] `commonLabels`
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

Status of support for other features:

* [ ] Resource loading
  * [x] resource-config files on disk
  * [x] `kustomization.yaml` files on disk
  * [x] directories on disk (all resource-config files within)
  * [x] directories on disk (`kustomization.yaml` file within)
  * [ ] files/directories from git repo URLs

* [ ] Automatic name suffixing of generated resources
  * [x] Secrets
  * [ ] ConfigMaps

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
  non-compatible ways.
  * `patchesJson6902` accepts an inline `ops` array
  * `patchesJson6902` accepts a `gsub` op

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
k = Kustomize.load("./path/to/kustomization.yaml")

k.emit # Array of Hashes (the final resource-configs)
k.to_yaml_stream # String (merged YAML multi-document stream)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Plugin Development

TODO

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tsutsu/kustomizer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
