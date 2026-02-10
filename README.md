# VirtualEshopDB: End-to-End Retail Data Architecture

**VirtualEshopDB** is an end-to-end Data Engineering and Business Intelligence project designed to simulate a high-growth e-commerce environment. The project bridges the gap between raw transactional data and strategic decision-making by implementing a full data pipeline—from relational modeling and automated data synthesis to advanced analytical reporting.

---

## Database Design
The database is organized into six main sections: a Customer list for personal details, a Category and Product catalog to organize items (like grouping Laptops under Electronics), and the Order and Order_item records that act as the digital receipt for every sale. To keep everything accurate, a live Inventory_log tracks every stock change—whether an item is sold, returned, or restocked. This connected system ensures that every piece of information is perfectly recorded, providing the reliable data needed to create the final business reports and charts.





---

## Data Generation
The Python script acts as the store's data engine, automatically filling the database with realistic information. Using the Faker library, it generates 1,000 unique Customers, a diverse Product catalog, and 5,000 Orders with a complete Inventory_log.

You can easily adjust the size of the database to simulate a much larger or smaller business by changing the values in the Configuration section of `PoupulateScript.py`:

```python
# Change these values to scale your data
num_customers = 1000   # Increase for more users
num_products = 500     # Increase for a bigger catalog
num_orders = 5000      # Increase for more sales history
num_logs = 10000       # Increase for more inventory tracking
```

## Analytical SQL Logic
I wrote custom scripts to convert raw data into key business metrics, such as category profitability, customer rankings, and product associations. This process summarizes the data for direct use in the Power

---

## Business Intelligence Dashboard
The **Power BI Dashboard** is the project's interactive visual layer.It connects directly to the SQL-processed data to track business health through dynamic charts and KPIs


Users can easily filter the entire report by month or year, allowing stakeholders to instantly compare performance trends and seasonal growth[cite: 5, 6].

---

## 🛠️ Technical Stack
* **Data Modeling:** Oracle SQL Developer Data Modeler for the design of both Logical and Relational entity-relationship diagrams (ERDs)
* **Data Generation:** Python 3.x using the **Faker** library
* **Advanced Analytics:** Oracle SQL Developer 
* **Reporting:** Power BI Desktop for data visualization
