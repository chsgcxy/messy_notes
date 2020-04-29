# Node-SubSystem

[TOC]

编译栈里面任何一个语言对象都是Node的子类

> We faced a constant changing of the compiler API for the need of research. We need a new language object or IR node whenever we want to test out new primitives. However, we don’t want to change our API from time to time. Besides that, we also want to

- be able to serialize any language object and IRs
- be able to explore, print, and manipulate the IR objects in front-end language to do quick prototyping.

Node 和 NodeRef 至关重要， 这两个base有很多subclass，每一个Node的subclass都对应一个NodeRef的subclass，用来返回对应的Node

## Class-Diagram

```plantuml
class AttrVisitor {
    {method} +virtual void Visit(const char* key, double* value) = 0;
    {method} +virtual void Visit(const char* key, int64_t* value) = 0;
    {method} +virtual void Visit(const char* key, uint64_t* value) = 0;
    {method} +virtual void Visit(const char* key, int* value) = 0;
    {method} +virtual void Visit(const char* key, bool* value) = 0;
    {method} +virtual void Visit(const char* key, std::string* value) = 0;
    {method} +virtual void Visit(const char* key, void** value) = 0;
    {method} +virtual void Visit(const char* key, Type* value) = 0;
    {method} +virtual void Visit(const char* key, NodeRef* value) = 0;
    {method} +virtual void Visit(const char* key, runtime::NDArray* value) = 0;
    {method} +virtual void Visit(const char* key, runtime::Object* value) = 0;
}

class NodeIndexer {
    {method} +void Visit(const char* key, double* value);
    {method} +void Visit(const char* key, int64_t* value);
    {method} +void Visit(const char* key, uint64_t* value);
    {method} +void Visit(const char* key, int* value);
    {method} +void Visit(const char* key, bool* value);
    {method} +void Visit(const char* key, std::string* value);
    {method} +void Visit(const char* key, void** value);
    {method} +void Visit(const char* key, Type* value);
    {method} +void Visit(const char* key, NodeRef* value) final {MakeIndex(value->node_.get());};
    {method} +void Visit(const char* key, runtime::NDArray* value);
    {method} +void Visit(const char* key, runtime::Object* value);
    {method} +void MakeIndex(Node* node);
}

class NodeAttrSetter {
    {method} +void Visit(const char* key, double* value);
    {method} +void Visit(const char* key, int64_t* value);
    {method} +void Visit(const char* key, uint64_t* value);
    {method} +void Visit(const char* key, int* value);
    {method} +void Visit(const char* key, bool* value);
    {method} +void Visit(const char* key, std::string* value);
    {method} +void Visit(const char* key, void** value);
    {method} +void Visit(const char* key, Type* value);
    {method} +void Visit(const char* key, NodeRef* value);
    {method} +void Visit(const char* key, runtime::NDArray* value);
    {method} +void Visit(const char* key, runtime::Object* value);
}

class JSONAttrGetter {
    {method} +void Visit(const char* key, double* value);
    {method} +void Visit(const char* key, int64_t* value);
    {method} +void Visit(const char* key, uint64_t* value);
    {method} +void Visit(const char* key, int* value);
    {method} +void Visit(const char* key, bool* value);
    {method} +void Visit(const char* key, std::string* value);
    {method} +void Visit(const char* key, void** value);
    {method} +void Visit(const char* key, Type* value);
    {method} +void Visit(const char* key, NodeRef* value);
    {method} +void Visit(const char* key, runtime::NDArray* value);
    {method} +void Visit(const char* key, runtime::Object* value);
    {method} +void Get(Node* node);
}

class JSONAttrSetter {
    {method} +void Visit(const char* key, double* value);
    {method} +void Visit(const char* key, int64_t* value);
    {method} +void Visit(const char* key, uint64_t* value);
    {method} +void Visit(const char* key, int* value);
    {method} +void Visit(const char* key, bool* value);
    {method} +void Visit(const char* key, std::string* value);
    {method} +void Visit(const char* key, void** value);
    {method} +void Visit(const char* key, Type* value);
    {method} +void Visit(const char* key, NodeRef* value);
    {method} +void Visit(const char* key, runtime::NDArray* value);
    {method} +void Visit(const char* key, runtime::Object* value);
    {method} +void Set(Node* node);
}

NodeIndexer --|> AttrVisitor
NodeAttrSetter --|> AttrVisitor
JSONAttrGetter --|> AttrVisitor
JSONAttrSetter --|> AttrVisitor


class Node {
    {field} +static constexpr const char* _type_key = "Node";
    {method} +virtual void VisitAttrs(AttrVisitor* visitor) {}
    {method} +inline NodePtr<Node> GetNodePtr() const;
    {method} +template<typename T> inline bool is_type() const;
}

class TensorNode {
    {field} +static constexpr const char* _type_key = "Tensor";
    {method} +void VisitAttrs(AttrVisitor* v);
    {method} +TVM_DLL static Tensor make(Array<Expr> shape, Type dtype, Operation op, int value_index);
}

class IterVarNode {
    {field} +static constexpr const char* _type_key = "IterVar";
    {method} +void VisitAttrs(AttrVisitor* v);
    {method} +TVM_DLL static IterVar make(Range dom, Var var, IterVarType iter_type, std::string thread_tag = "");
}

class CommReducerNode {
    {field} +static constexpr const char* _type_key = "CommReducer";
    {method} +void VisitAttrs(AttrVisitor* v);
}

class BufferNode {
    {field} +static constexpr const char* _type_key = "Buffer";
    {method} +void VisitAttrs(AttrVisitor* v);
    {method} +TVM_DLL static Buffer make(...);
}

BufferNode -up-|> Node
CommReducerNode -up-|> Node
IterVarNode -up-|> Node
TensorNode -up-|> Node

class NodeRef {
    {field} +NodePtr<Node> node_;
    {method} +inline size_t hash() const;
    {method} +inline const Node* operator->() const;
    {method} +template<typename T> inline const T *as() const;
}

class "template<typename Y> NodePtr" as NodePtr{
    {field} -NodeBase* data_{nullptr};
    {method} +T* get() const {return static_cast<T*>(data_);}
    {method} +NodePtr(const NodePtr<T>& other);
}

class NodeBase {
    {field} -std::atomic<int> ref_counter_{0};
    {method} +NodeBase(const NodeBase& other);
}

Node -right-|> NodeBase
NodeRef -up- AttrVisitor
NodePtr --> NodeBase 
NodeRef --> NodePtr
```
