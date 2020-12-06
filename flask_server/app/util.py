import time

def timeit(func):
    def wrapped(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        stop = time.time()
        print("time taken: {}s".format(stop-start))
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

def convert_to_int(number, base=None):
    return int(number, base)

def convert_to_base(number, base): 
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
    if number < base:
        return chars[number] 
    else: 
        return convert_to_base(number // base, base) + chars[number % base] 

def round_off(number, sf):
    fmt_string = "{:." + str(sf) + "f}"
    rounded_off = fmt_string.format(number)
    rounded_down = int(number)
    if float(rounded_off) - rounded_down == 0:
        return str(rounded_down)
    else:
        return rounded_off

def average(lst):
    return sum(lst)/len(lst)
