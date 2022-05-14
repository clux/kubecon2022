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
- purpose of this talk is to give a quick ecosystem tour

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
### Code Generation

- CustomResource
- kopium
- schemars
- k8s-openapi
- k8s-pb


notes:
- multiple parts - minimize the amount of boilerplate code you have to write
- lots of efforts around - not just from us
- schemars and k8s-openapi are maintained by other people

---
### Codegen; k8s-openapi

not ours

---
### Codegen; k8s-pb

our wip protobuf rewrite

notes:
- structs only exists if we have schemas for them
- core kubernetes schemas are released by kubernetes
- we parse them and generate rust centered structs for them

---
### Codegen; CustomResource derive

```rust
[derive(CustomResource, Deserialize, Serialize, Clone, Debug, JsonSchema)]
#[kube(kind = "Document", group = "kube.rs", version = "v1", namespaced)]
#[kube(status = "DocumentStatus", shortname = "doc")]
pub struct DocumentSpec {
    title: String,
    hide: bool,
    content: String,
}
```

notes:
- creates a Document type; that behaves as a k8s-openapi type
- we can generate crds... wtf how?

---
### Codegen; Schemars

recursive impl to get schemas

notes:
- very good

---
### Codegen; kopium

taking openapi schemas and generating rust structs

notes:
- taking openapi schemas and generating rust structs
- if you have a go controller, take its schema
- run it through kopium and you got half of a rust controller
- at least that's the goal






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
### Runtime; watcher

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
### Runtime; reflector

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
### Runtime; recorder

```rust
let recorder = Recorder::new(client, reporter, objref);
recorder.publish(Event {
    type_: EventType::Normal,
    reason: "HiddenDoc".into(),
    note​s: Some(format!("Hiding `{}`", name)),
    action: "Reconciling".into(),
    secondary: None
}).await
```

notes:
- parts of the client-go special helper tools
- eventrecorder fairly common that that's pretty clean already
- creates events, shows up in kubectl describe
- NB: zwsp in notes...

---
### Runtime; conditions

```rust
let crds: Api<CustomResourceDefinition> = Api::all(client);
let name = "documents.kube.rs";
let cond = conditions::is_crd_established();
let time = Duration::from_secs(10);
timeout(time, await_condition(crds, name, cond)).await?;
```

notes:
- conditions - abstraction that watches until a certain state in the status object has been seen
- we expose some basic conditions; is_deleted, is_crd_established, is_pod_running, but beyond that currently have small helpers
- tricky to write generically because objects don't need to have same fields, even spec/status conventions are even maintained within kubernetes
- can make this easier with next object generation setup (by selectively generating traits such as HasSpec and HasStatus or HasConditions)

---
### Runtime; controller

```rust
let ctx = Arc::new(Data { client });
Controller::new(crdapi, lp)
    .owns(configmaps, lp)
    .run(reconcile, error_policy, ctx)
```

notes:
- controllers. api has similar conventions to controller runtime.
- you configure your main api, here some crd
- configure an owned resource (here configmaps), that will trigger reconcile of owning object by traversing ownerAnnotations
- you pass in two functions; reconcile and error_policy
- and you then have to write a reconciler

---
### Runtime; reconcilers

```rust
#[instrument(skip(ctx, doc))]
async fn reconcile(doc: Arc<Document>, ctx: Arc<Data>)
    -> Result<Action, Error>
{
    let client = ctx.client.clone();
    let ns = doc.namespace().unwrap();
    let docs: Api<Document> = Api::namespaced(client, &ns);
    // TODO: use doc spec to create/update owned resources
    Ok(Action::requeue(Duration::from_secs(30 * 60)))
}
```

notes:
- reconciler ends up like this - kube invokes it when your object changes
- or anything it owns or watches changes
- but it figures out what's the parent and that's what you get called for
- also get context you passed in.
- then you get to correct the state of the world.
- it's all very fun writing idempotent reconcilers, and i could talk for days about it
- we have a whole section dedicated to controller writing on our website - not all done - but if you need a controller go read it


---
### Runtime; finalizers

```rust
finalizer(&api, "docs.kube.rs/cleanup", obj, |event| async {
    match event {
        Event::Apply(cm) => apply(cm, &secrets).await,
        Event::Cleanup(cm) => cleanup(cm, &secrets).await,
    }
}).await
```

notes:
- common patterns like finalizers we have helpers
- that
- you can split your main reconcile into two fns apply/cleanup that you create
- and then the

<!--
---
### Runtime End

- docs.rs [reflector](https://docs.rs/kube/latest/kube/runtime/fn.reflector.html)
- docs.rs [watcher](https://docs.rs/kube/latest/kube/runtime/fn.watcher.html)
- docs.rs [conditions](https://docs.rs/kube/latest/kube/runtime/wait/conditions/index.html)
-->

---
### Runtime End

- [kube.rs controller guide](https://kube.rs/controllers/intro/)
- docs.rs [Controller](https://docs.rs/kube/latest/kube/runtime/struct.Controller.html)
- docs.rs [finalizer](https://docs.rs/kube/latest/kube/runtime/finalizer/fn.finalizer.html)

---
### Runtime Examples

- [version-rs](https://github.com/kube-rs/version-rs/blob/main/version.rs)
- [controller-rs](https://github.com/kube-rs/controller-rs)

notes:
- 100 line reflector with axum, tracing, presents a deployment api
- best practices controller that we update with kube-rs; tracing, metrics, logs, crd generation from schema and kube-derive






---
### Lacks

- apiconfigurations
- structs not ideal yet - not all generic
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
