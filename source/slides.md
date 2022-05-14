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
### Client Runthrough

Rust Kubernetes Client

notes:
- first of all we are a client library
- you can do all api operations on k8s resources

---

### Client Runthrough 1

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
### Client Runthrough 2

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
### Client Runthrough 3

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
### Client Runthrough 4

```rust
let pods: Api<Pod> = Api::default_namespaced(client);
let status = pods.get_status("blog").await?
```

notes:
- standard subresource operations
- Status + Scale are the two main generic subresources
- can patch/replace these

---
### Client Runthrough 5

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
### Client Runthrough 6

```rust
let pods: Api<Pod> = Api::default_namespaced(client);

let mut stream = pods.watch(&lp, "0").await?.boxed();
while let Some(we) = stream.try_next().await? {
    // TODO: match on we: WatchEvent
}
```

notes:
- streams; async iteration; unlike list where we had to await the full list
- here we await each element
- this is base api where you get WatchEvents
- we don't recommend you actually use this kubernetes api directly because of tons of footguns, it'll desync, reset on you, you need to bookkeep resourceversions etc.






















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
