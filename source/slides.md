### Kube Introduction

- Eirik Albrigtsen
- [github/clux](https://github.com/clux) / [@sszynrae](https://twitter.com/sszynrae)
- [https://kube.rs](https://kube.rs)
- slides at http://clux.github.io/kubecon2022

notes:
- eirik - one of the main maintainers on kube-rs.
- before we start off; here's a bunch a bunch of links, me, sources, slides
- go by clux on github, or that on twitter

---
### What is Kube

- Rust client for Kubernetes in the style of a more generic client-go <!-- .element: class="fragment" -->
- Runtime inspired by controller-runtime <!-- .element: class="fragment" -->
- Derive macro for CRDs inspired by kubebuilder <!-- .element: class="fragment" -->

notes:
- basically reimaginings of: client-go, controller-runtime, kubebuilder, for the rust world
- tons of people have helped make kube support almost as wide as the go land
- managed in a single repo that's versioned together
- CNCF sandbox

---
### Why Rust?

- Most loved language since 2015
- Developer experience
- High level, yet fast and safe
- Docs

notes:
- huge popularity, stackoverflow survey has topped it since 2015
- starting to get huge adoption in major companies
- for good reason; developer experience is amazing (error messages tell you what to do, compilers and linters can --fix your code, rust-analyzer, i'm never afraid of what i've missed when it compiles)
- expressive types that can deal with real world complexity, doesn't hide things
- Documentation experience is amazing TODO: image?
- ..and why for kubernetes? well, hope that kube-rs will help convince you to try.
- TODO: can do tons of images here...

---
### Rust Kubernetes Client

- Config
- Client
- Api


notes:
- first of all we are a client library; kube_client crate
- has Config (disk config repr or in-cluster evar repr)
- that can be turned into a Client
- with a client you can make api instances; do operations on k8s resources

---
### Client Standard

```rust
let client = Client::try_default().await?;
```

==

```rust
let config = Config::infer().await?
let Client = Client::try_from(config)?;
```

notes:
- 99% use case; checks local config, then does cluster auth
- creates a client from this inferred config with default parameters
- default parameters are very tuned and all the layers of these are available
- layers?

---
### Client Advanced

```rust
let config = Config::infer().await?;
let https = config.rustls_https_connector()?;
let service = tower::ServiceBuilder::new()
    .layer(config.base_uri_layer())
    .option_layer(config.auth_layer()?)
    .service(hyper::Client::builder().build(https));
let client = Client::new(service, config.default_namespace);
```

notes:
- layers; tower; service builder trait - complex thing great for api libs
- our Client is "just a Service" composed of our default layer and a connector
- closest thing we can get to sans-io in rust
- bring something that implements a Service and you can customize

---
### Client Standard

```rust
let client = Client::try_default().await?;
```

notes:
- in practice; just use the above, get light-weight hyper (likely in tree)
- we generally just figure out the most sensible thing
- our auth layer deals basic auth, bearer tokens, refresh tokens via files, oauth, or that scary exec based stuff that someone thought was a good idea, that's now coming back to bite everyone. but yeah, we support everything
- and when you have a Client, you can query the api

---

### Api Runthrough 1

```rust
let nodes: Api<Node> = Api::all(client);
let n = nodes.get("k3d-main-server-0").await?;

for node in nodes.list(&ListParams::default()).await? {
    println!("Found node {}", node.name());
}
```

notes:
- you can do get and list operations on resources (here nodes)
- note async syntax in rust to await return from api

---
### Api Runthrough 2

```rust
let pods: Api<Pod> = Api::default_namespaced(client);
let p = pods.get("blog").await?;

for pod in pods.list(&ListParams::default()).await? {
    println!("Found pod {}", pod.name());
}
```

notes:
- api is generic, same interface for all pods
- can do all the things, delete, delete_collection, create, patch

---
### Api Runthrough 3

```rust
let pods: Api<Pod> = Api::default_namespaced(client);
let p: Pod = serde_json::from_value(json!({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "blog" },
    "spec": {
        "containers": [{
            "name": "blog",
            "image": "clux/blog:0.1.0"
        }],
    }
}))?;
pods.patch("blog", &serverside, &Patch::Apply(p)).await?
```

notes:
- you can patch, or serverside apply
- either from openapi generated structs
- or you can force serialize into structs with this syntax checked json macro

---
### Api Runthrough 4

```rust
let pods: Api<Pod> = Api::default_namespaced(client);
let status = pods.get_status("blog").await?
```

notes:
- standard subresource operations
- Status + Scale are the two main generic subresources
- can patch/replace these

---
### Api Runthrough 5

```rust
let pods: Api<Pod> = Api::default_namespaced(client);

let cmd = vec!["sh", "-c", "for i in $(seq 1 3); do date; done"]
let params = AttachParams::default().stderr(false);
let attached = pods.exec("blog", cmd, &params).await?;
```

notes:
- we also implement all the special subresources for special case resources
- you can exec into pods, and you get a set of io streams back that you can tail or pipe into another streams
- i.e. take stdin from your cli and pipe it to a container => teleport


---
### Api Runthrough 6

```rust
let pods: Api<Pod> = Api::default_namespaced(client);

let mut stream = pods.watch(&lp, "0").await?.boxed();
while let Some(we) = stream.try_next().await? {
    // TODO: match on we: WatchEvent
}
```

notes:
- streams; async iteration; unlike list where we had to await the full list
- here we await each element - using TryStream trait
- this is base api where you get WatchEvents
- we don't recommend you actually use this kubernetes api directly because of tons of footguns, it'll desync, reset on you, you need to bookkeep resourceversions etc.


---
### Api End

=> docs.rs/kube or kube-rs repo under examples

- docs.rs [`kube::Client`](https://docs.rs/kube/latest/kube/struct.Client.html)
- docs.rs [`kube::Api`](https://docs.rs/kube/latest/kube/struct.Api.html)
- [examples](https://github.com/kube-rs/kube-rs/tree/master/examples)
- [examples/kubectl](https://github.com/kube-rs/kube-rs/blob/master/examples/kubectl.rs)

notes:
- basic of a library
- we support pretty much the full api, so that's super close to client-gold
- but we don't have protobuf support yet, we have a WIP for it



---
### Runtime

- watcher
- reflector
- Controller


notes:
- we are also runtime; kube_runtime runtime, similar to controller-runtime
- has api abstractions
- watcher - to continuously watch an api forever
- reflector - to cache data
- controllers, glue it all together so you can build a reconciler around an owned object

---
### Runtime Runthrough 1

```rust
let nodes: Api<Node> = Api::all(client);
let mut stream = watcher(nodes, lp).applied_objects().boxed();
while let Some(n) = stream.try_next().await? {
    info!("saw node {}", n.name())
}
```

notes:
- watchers; state machinery to keep a single continuous stream
- when you flatten the internal watch events stream with `applied_objects` you just get a stream of objects
- and it stays open forever
- works for every object because it takes an Api

---
### Runtime Runthrough 2

```rust
let nodes: Api<Node> = Api::all(client);
let (reader, writer) = reflector::store();
let rf = reflector(writer, watcher(nodes, lp))
let stream = rf.applied_objects().boxed();
```

notes:
- reflectors; something you can chain a watcher stream into
- maintains a map of what's currently in the cluster
- writer is moved in to the reflector, you keep a reader handle
- can pass the reader handle to a web server or whatever, it's clonable
- and provides a way to query the cluster without making extra api calls


---
### Runtime Runthrough 3

- event recorder
- conditions
- controller
- finalizer

```rust

```





---
### Lacks

- apiconfigurations
- structs not ideal yet
- protobuf work



---
### Why Not Rust

- Kubernetes + client-go comes first <!-- .element: class="fragment" -->
- Edge cases <!-- .element: class="fragment" -->


notes:
- Kubernetes, and client-go are going to be where features are originally developed
- not everything will be supported (protobuf transport being the big outstanding piece)
- more obscure features might not exist, or might have edge cases, might have to submit issues
- likely not going to save a

---
### Why Rust

- Battle tested generic interfaces
- No generated code in tree
- Memory optimization
- Active community
- Simpler codebase to follow
- Rust is taking over (some areas)

notes:
- all sorts of lofty ideas as to why you might choose rust over go here
- but the one that sticks out to me is that this is a much simpler codebase to follow
- and the language makes it very hard for you to make mistakes
- so really, if you are here, it's likely you are here because you are self-selecting for rust


---
### What You Can Do
CONTROLLERS, watchers
Schema transformations
no need to reinvent the wheel
RIIR with kopium

---
### Getting Started

- kube.rs site
- controller guide

---
### Getting Involved

- discord
- github discussions / issues

---
### QA


notes:
- re-highlight links, etc
