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
