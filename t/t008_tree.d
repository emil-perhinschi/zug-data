#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main()
{
    import zug.tap;
    import zug.tree;

    auto tap = Tap("t008_tree");
    tap.verbose(true);

    import std.stdio;

    {
        auto tree = new Nary!(string).NaryTree();
        auto root = tree.create_node(0, "this is root");
        root.add_child("this is the first child");
        tap.ok(tree.nodes_list.length == 2);
        root.add_child("this is the second child of the root");
        root.add_child("this is the third child of the root");
        auto first_node_above_root = root.child(0);
        tap.ok(first_node_above_root.id == 2);
        tap.ok(first_node_above_root.data == "this is the first child");

        auto second_node_above_root = root.child(1);
        tap.ok(second_node_above_root.id == 3);
        tap.ok(second_node_above_root.data == "this is the second child of the root");
        tap.ok(tree.nodes_list.length == 4);

        second_node_above_root.add_child("second level first child");
        second_node_above_root.add_child("second level second child");
        second_node_above_root.add_child("second level third child");

        tap.ok(tree.nodes_list.length == 7);

        auto path = second_node_above_root.path();
        tap.ok(path == [1, 3]);

        auto path_to_third_level = second_node_above_root.child(0).path;
        tap.ok(path_to_third_level == [1, 3, 5]);
        auto test_path_is_right = path ~ second_node_above_root.child(0).id;
        tap.ok(test_path_is_right == path_to_third_level);
        auto last_child = second_node_above_root.child(0);
        auto path_string = last_child.path_to_string(" # ");
        tap.ok(
                "this is root # this is the second child of the root # second level first child" == path_string);
    }

    {
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
        auto vim = software.add("Vim");

        auto mint = linux.add("Mint");
        auto devuan = linux.add("Devuan");

        tap.ok("www.example.com/products/software/Linux/Devuan" == devuan.path_to_string("/"));
    }

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

        for (int i = 0; i < 10; i++)
        {
            another.add_child(10234 + i);
        }
        tap.ok( another.children.length == 10 );
    }

    tap.done_testing();
}
