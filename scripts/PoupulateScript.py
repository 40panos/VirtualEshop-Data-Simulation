from faker import Faker
import random
import os

fake = Faker()

script_dir = os.path.dirname(os.path.abspath(__file__))
input_ddl = os.path.join(script_dir, "..", "database", "Eshop_structure.sql") 
output_sql = os.path.join(script_dir, "..", "database", "Eshop_structure_full.sql")


# --- CONFIGURATION (SCALING PARAMETERS) ---
num_customers = 1000
num_products = 500
num_orders = 5000
num_logs = 10000

    # Define Category hierarchy
    # (ID, Name, Parent_ID)
categories = [
        # Level 1: Main categories
        (1, 'Electronics', 'NULL'),
        (2, 'Home Appliances', 'NULL'),
        (3, 'Computing', 'NULL'),
        
        # Level 2: Subcategories
        (4, 'Smartphones', 1),    
        (5, 'Audio & Video', 1),  
        (6, 'Laptops', 3),        
        (7, 'Peripherals', 3),    
        
        # Level 3: Sub-subcategories
        (8, 'Gaming Laptops', 6), 
        (9, 'Office Laptops', 6)  
]
    
try:
    with open(input_ddl, "r", encoding="utf-8") as f:
        ddl_content = f.read()
    print(" DDL file read successfully!")
except FileNotFoundError:
    print(f"❌ Error: File '{input_ddl}' not found.")
    exit()

    # 2. Initialize output file and write schema
with open(output_sql, "w", encoding="utf-8") as f:
    # Write table structure
    f.write("-- TABLE STRUCTURE\n") 
    f.write(ddl_content)
    f.write("\n\nSET DEFINE OFF;\n")

    # --- 1. CATEGORIES ---
    f.write("\n-- INSERT CATEGORIES\n")
    

    for c_id, name, parent in categories:
        # Generate INSERT statements for Category table
        f.write(f"INSERT INTO Category (category_id, category_name, parent_id) "
                f"VALUES ({c_id}, '{name}', {parent});\n")

    print("Categories processed!")
    
    # --- 2. CUSTOMERS ---
    f.write("\n-- INSERT CUSTOMERS\n")    
    customer_reg_dates = {} # Map to store registration dates for order validation
    for i in range(1, num_customers + 1):
            first = fake.first_name()
            last = fake.last_name()
            email = fake.email()
            city = fake.city()
            chance = random.random()
            if chance < 0.70:
                # 70% probability: Registered 2-3 years ago
                reg_date = fake.date_between(start_date='-3y', end_date='-2y')
            else:
                # 30% probability: Registered within the last 2 years
                reg_date = fake.date_between(start_date='-2y', end_date='today')
            customer_reg_dates[i] = reg_date
            # Generate INSERT statements for Customer table
            f.write(f"INSERT INTO Customer (customer_id, first_name, last_name, email, city, registration_date) "
                    f"VALUES ({i}, '{first}', '{last}', '{email}', '{city}', TO_DATE('{reg_date}', 'YYYY-MM-DD'));\n")

    print(f"Generated {num_customers} customers!")

    # --- 3. PRODUCTS ---
    
    product_data = {}# Dictionary for price tracking
    f.write("\n-- INSERT PRODUCTS\n")
    
    # Logic for realistic product names based on category
    product_logic = {
        4: ["iPhone", "Samsung Galaxy", "Google Pixel", "Xiaomi"], 
        5: ["Sony Headphones", "Bose Speaker", "LG Soundbar"],     
        8: ["Razer Blade", "MSI Katana", "Alienware x16"],         
        9: ["MacBook Air", "Dell XPS", "Lenovo ThinkPad"]          
    }

    
    for i in range(1, num_products + 1):
        # 1. Select random category
        cat_id = random.choice(list(product_logic.keys()))
        
        # 2. Generate product name
        brand = random.choice(product_logic[cat_id])
        p_name = f"{brand} {fake.word().upper()} {random.randint(10, 99)}"
        
        # 3. Calculate prices (Profit margin: 20-40%)
        l_price = round(random.uniform(200.0, 2000.0), 2)
        c_price = round(l_price * random.uniform(0.6, 0.8), 2)
        product_data[i] = {
        'list_price': l_price,
        'cost_price': c_price
    }


        # 4. Generate SKU
        sku = fake.ean8()
        
        # Write to SQL file
        f.write(f"INSERT INTO Product (product_id, product_name, list_price, cost_price, sku, category_id) "
                f"VALUES ({i}, '{p_name}', {l_price}, {c_price}, '{sku}', {cat_id});\n")

    print(f"Generated {num_products} products!")
    
    #--- 4. ORDERS ---
    f.write("\n-- INSERT ORDERS\n")
    
    statuses = ['Completed', 'Pending', 'Shipped', 'Cancelled']
    weights = [0.70, 0.10, 0.10, 0.10]

    for i in range(1, num_orders + 1):
        # Link to random customer and ensure order_date >= registration_date
        cust_id = random.randint(1, num_customers) 
        reg_date_of_cust = customer_reg_dates[cust_id]
        o_date = fake.date_between(start_date=reg_date_of_cust, end_date='today')
        status = random.choices(statuses, weights=weights, k=1)[0]


        f.write(f"INSERT INTO \"Order\" (order_id, order_date, status, customer_id) "
                f"VALUES ({i}, TO_DATE('{o_date}', 'YYYY-MM-DD'), '{status}', {cust_id});\n")

    print(f"Generated {num_orders} orders!")

# --- 5. ORDER ITEMS ---
    f.write("\n-- INSERT ORDER ITEMS\n")
    
    order_item_id_counter = 1
    for order_id in range(1, num_orders + 1):
        # Determine number of products per order
        items_count = random.randint(1, 4)
        
        # Simulate high-demand products (Top 20 products)
        if random.random() < 0.40:  
            selected_products = random.sample(range(1, 21), items_count)
        else:  
            selected_products = random.sample(range(1, num_products + 1), items_count)
        
        for prod_id in selected_products:
            # 1. Retrieve list price
            u_price = product_data[prod_id]['list_price']
            
            # 2. Set item quantity
            qty = random.randint(1, 3)
            
            # 3. Write INSERT
            f.write(f"INSERT INTO Order_item (order_item_id, quantity, unit_price, product_id, order_id) "
                    f"VALUES ({order_item_id_counter}, {qty}, {u_price}, {prod_id}, {order_id});\n")
            
            order_item_id_counter += 1

    print(f"Generated {order_item_id_counter - 1} order items!")

# --- 6. INVENTORY LOG ---
    f.write("\n-- INSERT INVENTORY LOG\n")
    

    for i in range(1, num_logs + 1):
        prod_id = random.randint(1, num_products)
        log_date = fake.date_between(start_date='-2y', end_date='today')
        
        # Determine log type and quantity adjustment
        reason = random.choice(['Sale', 'Restock', 'Return'])
        if reason == 'Restock':
            amount = random.randint(10, 50)
        elif reason == 'Return':
            amount = random.randint(1, 2)
        else:
            amount = random.randint(-10, -1)
            
        f.write(f"INSERT INTO Inventory_log (log_id, change_amount, reason, log_date, product_id) "
                f"VALUES ({i}, {amount}, '{reason}', TO_DATE('{log_date}', 'YYYY-MM-DD'), {prod_id});\n")
    print(f"Generated {num_logs} inventory logs!")
    f.write("\nCOMMIT;\n")

print(f"Script complete. Output: '{output_sql}'")