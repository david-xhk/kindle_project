import time

def timeit(func):
    def wrapped(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        stop = time.time()
        print("time taken: %ss" % (stop-start))
        return result
    return wrapped

def convert_flat_to_hierarchical(flat_tree):
    tree = {"name": "root", "children": {}}
    for path in flat_tree:
        pointer = tree
        for name in path:
            if name not in pointer["children"]:
                pointer["children"][name] = {"name": name, "children": {}}
            pointer = pointer["children"][name]
    return tree
