module zug.tree;

unittest
{
    import std.stdio;

    auto node = new Nary!(int).NaryNode();
    node.data(1001);

    auto tree = new Nary!(int).NaryTree();
    tree.root(node);

    auto new_node = tree.create_node(node.id, 1002);
    auto another = tree.create_node(0, 1003);

    // writeln(tree.node(1).data);
    // writeln(node.children);
    // writeln(tree.nodes_list);
    // writeln(new_node.tree().nodes_list);

    for(int i = 0; i < 10; i++) {
        another.add_child(10234 + i);
    }
    assert(another.children.length == 10);
}

unittest
{
    import std.stdio;

    auto tree = new Nary!(string).NaryTree();
    auto root = tree.create_node(0, "this is root");
    root.add_child("this is the first child");
    assert(tree.nodes_list.length == 2);
    root.add_child("this is the second child of the root");
    root.add_child("this is the third child of the root");
    auto first_node_above_root = root.child(0);
    assert(first_node_above_root.id == 2);
    assert(first_node_above_root.data == "this is the first child");

    auto second_node_above_root = root.child(1);
    assert(second_node_above_root.id == 3);
    assert(second_node_above_root.data == "this is the second child of the root");
    assert(tree.nodes_list.length == 4);

    second_node_above_root.add_child("second level first child");
    second_node_above_root.add_child("second level second child");
    second_node_above_root.add_child("second level third child");

    assert(tree.nodes_list.length == 7);

    auto path = second_node_above_root.path();
    assert(path == [1, 3]);

    auto path_to_third_level = second_node_above_root.child(0).path;
    assert(path_to_third_level == [1,3,5]);
    auto test_path_is_right = path ~ second_node_above_root.child(0).id;
    assert(test_path_is_right == path_to_third_level);
    auto last_child = second_node_above_root.child(0);
    auto path_string = last_child.path_to_string(" # ");
    assert("this is root # this is the second child of the root # second level first child" == path_string);
}

// let's simulate a web site 
unittest
{
    import std.stdio;
    auto tree = new Nary!(string).NaryTree();
    auto root = tree.create_node(0, "www.example.com");

    auto products = root.add_child("products");
    auto demos = root.add_child("demos");
    auto subscriptions = root.add_child("subscriptions");
    auto plans = root.add_child("plans");
    auto search = root.add_child("search");

    auto books = products.add_child("books");
    auto ebooks = products.add("ebooks");
    auto articles = products.add("articles");
    auto software = products.add("software");

    auto linux = software.add("Linux");
    auto emacs = software.add("Emacs");
    auto vim   = software.add("Vim");
    
    auto mint  = linux.add("Mint");
    auto devuan = linux.add("Devuan");

    assert("www.example.com/products/software/Linux/Devuan" == devuan.path_to_string("/"));
}


template Nary(DataType)
{


    alias NaryTreeCallback = NaryTree delegate();


    class NaryNode
    {

    protected:
        size_t _id;
        size_t[] _children;
        DataType _data;
        size_t _parent_id = 0;
    public:
        NaryTreeCallback tree;

        size_t id()
        {
            return this._id;
        }

        void id(size_t id_value)
        {
            this._id = id_value;
        }

        void children(size_t[] new_children)
        {
            this._children = new_children;
        }

        NaryNode[] children()
        {
            NaryNode[] children;
            for (int i = 0; i < this._children.length; i++)
            {
                children ~= this.tree().node(this._children[i]);
            }
            return children;
        }

        NaryNode child(size_t index)
        {
            return this.tree().node(this._children[index]);
        }

        NaryNode add_child(DataType data)
        {
            auto child = this.tree().create_node(this.id, data);
            this._children ~= child.id;
            return child;
        }

        alias add = add_child;

        void remove_child(size_t child_id)
        {
            import std.array;
            import std.algorithm;

            this.tree().remove_node(child_id);
            remove(this._children, child_id);
        }

        void parent(size_t new_parent_id)
        {
            this._parent_id = new_parent_id;
        }

        NaryNode parent()
        {
            if (this._parent_id != 0)
            {
                return this.tree().node(this._parent_id);
            }
            return null;
        }

        DataType data()
        {
            return this._data;
        }

        void data(DataType new_data)
        {
            this._data = new_data;
        }

        size_t[] path()
        {
            import std.stdio;

            if (this.parent is null) {
                return [ this.id ];
            }
            else {
                auto result = this.parent.path();
                result ~= this.id;
                return result;
            }
        }

        string path_to_string(string separator)
        {
            import std.conv: to;
            string result;
            foreach (size_t item; this.path) {
                auto current_node = this.tree().node(item);
                result ~= 
                    ( current_node.parent is null ? "" : separator ) 
                    ~ current_node.data().to!string;
            }
            return result;
        }

    }

    class NaryTree
    {

        size_t root_id; // 0 means no root or "don't know"
        size_t last_node_id; // sequence for node ids
        NaryNode[size_t] nodes_list;

        NaryNode root()
        {
            if (this.root_id == 0)
            {
                return null;
            }

            return this.nodes_list[this.root_id];
        }

        size_t next_node_id()
        {
            this.last_node_id++;
            return this.last_node_id;
        }

        void root(NaryNode node)
        {
            if (node.id == 0)
            {
                node.id = this.next_node_id;
            }
            this.root_id = node.id;
            this.nodes_list[node.id] = node;
        }

        NaryNode create_node(size_t parent_id, DataType data)
        {
            auto node = new NaryNode();
            node.parent(parent_id);
            node.data(data);
            if (this.last_node_id == 0)
            {
                if (parent_id != 0)
                {
                    throw new Error("This tree has no root, cannot sent a parent");
                }

                node.id(1);
                this.root(node);
                this.last_node_id = node.id;
            }
            else
            {
                node.id = this.last_node_id + 1;
                node.parent(parent_id);
                this.last_node_id += 1;
                this.nodes_list[node.id] = node;
            }
            node.tree = () => this;
            return node;
        }

        NaryNode node(size_t node_id)
        {
            return this.nodes_list[node_id];
        }

        void remove_node(size_t node_id)
        {
            this.nodes_list.remove(node_id);
        }
    }
}
