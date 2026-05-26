create database ecommerce;
use ecommerce;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    gender VARCHAR(10),
    city VARCHAR(100),
    state VARCHAR(100),
    signup_date DATE
);


CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department VARCHAR(100),
    salary DECIMAL(10,2),
    joining_date DATE,
    manager_id INT
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    stock_quantity INT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    payment_method VARCHAR(50),
    order_status VARCHAR(50),

    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    selling_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),

    FOREIGN KEY (order_id)
    REFERENCES orders(order_id),

    FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);
alter table order_items 
add column final_price decimal(10,2);

update order_items 
set final_price = (selling_price*quantity) - (selling_price*quantity)*discount_percent / 100;

-- 1.Find total number of customers.
select count(*) from customers;

-- 2. Find total number of orders placed.
select count(*) from orders;

-- 3. Find total revenue generated.
select sum(final_price) as total_revenue from order_items oi 
join orders o on 
o.order_id = oi.order_id 
where o.order_status  in ('Shipped','Delivered');

-- 4. Find average order value.
select round(sum(oi.final_price) / count(distinct o.order_id),2) as avg_order_value from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered');

-- 5. Find total quantity of products sold.
select sum(quantity) as total_products_sold from order_items oi 
join orders o on 
oi.order_id = o.order_id 
where o.order_status in ('Shipped','Delivered');

--  6. List all unique product categories.
select distinct category from products;

-- 7.Find total number of products available.
select count(product_id) from products;

-- 8.Find highest priced product.
select product_name , price from products
where price = (select max(price) from products);

-- 9.Find lowest priced product
select product_name , price from products 
where price = ( select min(price) from products);

-- 10.Find total stock available. 
select sum(stock_quantity) as total_quantity from products;


              -- 👥 Customer Analytics --
              
-- 11.Find top 10 customers based on total spending.

select c.customer_name, o.customer_id,sum(oi.final_price) as total_spending from orders o 
join customers c on 
o.customer_id = c.customer_id
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by customer_name ,customer_id 
order by total_spending desc
limit 10;

-- 12.Find customers who never placed any order.
select c.customer_id ,c.customer_name  from customers c
left join orders o on 
c.customer_id = o.customer_id 
where o.order_id is null;

-- 13.Find customers with more than 5 orders
select o.customer_id ,c.customer_name , count(o.order_id) total_orders from orders o
join customers c on 
o.customer_id = c.customer_id 
group by customer_id 
having total_orders > 5;

-- 14.Find customer retention rate.

with customer_orders as (select customer_id , count(order_id) as total_orders from orders 
					group by customer_id ),
	retained_customers as (select count(*) as retained_count from customer_orders 
						   where total_orders > 1),
	total_customers as (select count(*) as total_customers from customers)

select (retained_count * 100 / total_customers) as retention_rate from retained_customers,total_customers;

-- 15.Find repeat customers.
select o.customer_id ,c.customer_name, count(o.order_id) as total_orders from orders o
join customers c on 
o.customer_id = c.customer_id
group by customer_id
having total_orders > 1;

-- 16.Find customers from each state.
select state , count(customer_id) as total_customers from customers 
group by state;



-- 17.Find top spending state.

select c.state , sum(oi.final_price) as total_spending_amt from customers c 
join orders o on 
c.customer_id = o.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
group by c.state 
order by total_spending_amt desc 
limit 1;

-- 18.Find customer signup trend month-wise.
select monthname(signup_date) as month_,count(*) as total_customers from customers 
group by month(signup_date), month_
order by month(signup_date);

-- 19.Find average spending per customer.
select sum(oi.final_price) / count(distinct c.customer_id) as avg_spending from customers c 
join orders o on 
c.customer_id = o.customer_id 
join order_items oi  on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered');

-- 20 .Find customers who placed orders in multiple months.
select o.customer_id , c.customer_name, count(distinct date_format(o.order_date,'%Y-%m')) as order_count from orders o
join customers c on 
o.customer_id = c.customer_id
group by o.customer_id,c.customer_name 
having order_count > 1;

-- 📦 Product Analytics
	
    -- 21. Find top 10 selling products.
    select p.product_name,sum(oi.quantity) as total_quantity from products p
    join order_items oi on 
    p.product_id = oi.product_id
    join orders o on 
    oi.order_id = o.order_id 
    where o.order_status in ('Shipped','Delivered')
    group by p.product_name 
    order by total_quantity desc
    limit 10;
    
    -- 22.Find least selling products. 
    select p.product_name,sum(oi.quantity) as total_quantity from products p
    join order_items oi on 
    p.product_id = oi.product_id
    join orders o on 
    oi.order_id = o.order_id 
    where o.order_status in ('Shipped','Delivered')
    group by p.product_name 
    order by total_quantity asc
    limit 10;
    
    -- 23.Find highest revenue generating product.
    select p.product_name,sum(oi.final_price) as total_price from products p
    join order_items oi on 
    p.product_id = oi.product_id
    join orders o on 
    oi.order_id = o.order_id 
    where o.order_status in ('Shipped','Delivered')
    group by p.product_name 
    order by total_price desc
    limit 1;
    
    -- 24.Find category-wise sales.
    select p.category , sum(oi.final_price) as total_price from products p 
    join order_items oi on 
    p.product_id = oi.product_id 
    join orders o on 
    oi.order_id = o.order_id 
	where o.order_status in ('Shipped','Delivered')
    group by category;
    
    -- 25.Find category-wise profit.
    select p.category , sum(oi.final_price - (p.cost_price * oi.quantity)) as profit from products p
    join order_items oi on 
    p.product_id = oi.product_id 
    join orders o on 
    oi.order_id = o.order_id 
	where o.order_status in ('Shipped','Delivered')
    group by category;
    
    -- 26.Find products with low stock. 
select product_id , product_name , stock_quantity  from products
group by product_id ,  product_name 
order by stock_quantity asc 
limit 10;

-- 27.Find products never ordered.
select p.product_id , p.product_name from products p
left join order_items oi on
p.product_id = oi.product_id
where oi.order_id is null;

-- 28.Find average discount given per product. 
select p.product_id , p.product_name, round(avg(oi.discount_percent),2) as avg_discount from  products p
join order_items oi on 
p.product_id = oi.product_id 
group by p.product_id , p.product_name;
    
-- 29.Find products with highest discount. 
select p.product_id , p.product_name, max(oi.discount_percent) as highest_discount from  products p
join order_items oi on 
p.product_id = oi.product_id 
group by p.product_id , p.product_name
order by highest_discount desc 
limit 10;

-- 30.Find brand-wise sales performance. 


select p.brand,  sum(oi.final_price) as total_sales from  products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on 
oi.order_id = o.order_id 
where o.order_status in ('Shipped','Delivered')
group by p.brand;

-- Revenue & Profit Analysis

-- 31.Calculate total profit.
select sum(oi.final_price -(p.cost_price*oi.quantity)) as total_profit from order_items oi
join products p on 
oi.product_id = p.product_id
join orders o on 
oi.order_id = o.order_id 
where o.order_status in ('Shipped','Delivered');
 
 -- 32.Find monthly revenue trend. 
 select year(o.order_date) as year_, monthname(o.order_date) as month_ ,sum(oi.final_price) as total_revenue from orders o
 join order_items oi on 
 o.order_id = oi.order_id 
 where o.order_status in ('Shipped','Delivered')
 group by year_,month_,month(o.order_date)
 order by year_,month(order_date),month_;
 
 -- 33.Find monthly profit trend. 
 select year(o.order_date) as year_, monthname(o.order_date) as month_ ,sum(oi.final_price -(p.cost_price * oi.quantity)) as total_profit from orders o
 join order_items oi on 
 o.order_id = oi.order_id 
 join products p on 
 p.product_id = oi.product_id
 where o.order_status in ('Shipped','Delivered')
 group by year_,month_,month(o.order_date)
 order by year_,month(order_date),month_;
 
 -- 34.Find top profitable products.
  select p.product_id , p.product_name ,sum(oi.final_price -(p.cost_price * oi.quantity)) as total_profit from orders o
 join order_items oi on 
 o.order_id = oi.order_id 
 join products p on 
 p.product_id = oi.product_id
 where o.order_status in ('Shipped','Delivered')
 group by p.product_id , p.product_name
order by total_profit desc 
limit 10;

-- 35.Find loss-making products.
select p.product_id , p.product_name ,sum(oi.final_price -(p.cost_price * oi.quantity)) as total_profit from orders o
 join order_items oi on 
 o.order_id = oi.order_id 
 join products p on 
 p.product_id = oi.product_id
 where o.order_status in ('Shipped','Delivered') 
group by p.product_id , p.product_name
having total_profit < 0
order by total_profit asc;

-- 38.Find average revenue per order. 
select sum(oi.final_price) / count(distinct o.order_id) as avg_per_order from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered') ;

 -- 39.Find orders with highest revenue.
select o.order_id , sum(oi.final_price) as highest_revenue  from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered') 
group by order_id
order by highest_revenue desc ;

-- 40 . Find percentage contribution of each category to total revenue.

with cte as (select p.category , sum(oi.final_price) as total_revenue  from order_items oi 
join products p on 
oi.product_id = p.product_id 
join orders o on
oi.order_id = o.order_id
where o.order_status in ('Shipped','Delivered') 
group by p.category)
select category , round((total_revenue / sum(total_revenue) over()) * 100,2) as contribution from cte
order by contribution;

-- 40.Find year-over-year growth. 
with cte as (select year(o.order_date) as year_ , sum(final_price) as total_revenue from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered') 
group by year_)
select year_ , lag(total_revenue) over(order by year_) as previous_year_revenue,
  round(((total_revenue - lag(total_revenue) over(order by year_)) / lag(total_revenue) over(order by year_)) * 100,2) as YOY_growth from cte
  order by year_;

        -- 📍 Regional Business Analysis 
        
-- 41.Find top performing cities by sales.
select c.city , sum(oi.final_price) as total_sales from customers c 
join orders o on 
c.customer_id = o.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.city
order by total_Sales desc;

-- 42.Find top performing states by revenue. 
select c.state , sum(oi.final_price) as total_revenue from customers c 
join orders o on 
c.customer_id = o.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.state
order by total_revenue desc;

-- 43.Find state-wise order count. 
select c.state , count(distinct o.order_id) as orders from customers c
join orders o on 
c.customer_id = o.customer_id 
group by c.state;

-- 44.Find city-wise customer distribution. 
select city , count(customer_id) as customers from customers 
group by city;

-- 45.Find regions with low sales. 
select c.state , sum(oi.final_price) as total_sales from customers c 
join orders o on 
c.customer_id = o.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.state
order by total_sales asc;

          -- 💳 Payment & Order Analysis

-- 46.Find most used payment method. 
select payment_method , count(*) as counts from orders 
group by payment_method 
order by counts desc 
limit 1;

-- 47.Find payment method-wise revenue. 
select o.payment_method , sum(oi.final_price) as total_revenue from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by o.payment_method 
order by total_revenue desc;

-- 48.Find cancelled orders count 
select count(*) as cancelled_orders from orders 
where order_status = 'Cancelled';


-- 49.Find completed order percentage. 
	with s_d as (select count(*) as s_d_count from orders 
	where order_status in('Shipped','Delivered') ), 
	total as (select count(*) as total from orders)
	select round((s_d_count*100 / total),2) as order_percentage from s_d , total;   
    
-- 50.Find monthly order trend. 
select year(order_date) as year_,monthname(order_date) as month_ ,count(*) as orders from orders 
WHERE order_status IN ('Shipped','Delivered')
group by year_,month(order_date),month_
order by year_,month(order_date),month_ ;

-- 51.Find peak sales month.
select year(o.order_date) as year_, monthname(o.order_date) as month_ ,sum(oi.final_price) as total_sales from orders o
 join order_items oi on 
 o.order_id = oi.order_id 
 where o.order_status in ('Shipped','Delivered')
 group by year_,month_,month(o.order_date)
 order by total_sales desc 
 limit 1;
 
 -- 52.Find day with highest orders.
 
select date(order_date) as date_,count(*) as orders from orders 
WHERE order_status IN ('Shipped','Delivered')
group by date_
order by orders desc 
limit 10;

-- 53.Find average products per order. 
select round(sum(oi.quantity) / count(distinct o.order_id),2) as avg_prod_per_order from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered'); 

-- 54.Find orders with more than 3 products. 
select o.order_id , count(distinct oi.product_id) as products from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by o.order_id 
having count(distinct oi.product_id) > 3;

-- 55.Find order status distribution. 
select order_status , count(*) as count_ from orders 
group by order_status 
order by count_ desc;


         -- 👨‍💼 Employee Performance Analysis
         
-- 56.Find employee with highest salary. 
select employee_name , salary from employees 
order by salary desc
limit 1;

-- 57.Find department-wise average salary. 
select department, round(avg(salary),2) as salary from employees 
group by department
order by salary desc;

-- 58.Find employees joined in last 2 years. 
select employee_name from employees
where joining_date >= current_date()-interval 2 year;

-- 59.Find manager-wise employee count. 
select manager_id , count(*) as employee_count from employees 
where manager_id is not null
group by manager_id ;

-- 60.Find employee hierarchy using self join. 
select e.employee_id , e.employee_name as employee , m.employee_id as manager_id ,m.employee_name as manager from employees e 
left join employees m on 
e.manager_id = m.employee_id;

           -- 🔥 Advanced SQL Business Problems 
           
-- 61.Rank products based on revenue generated. 
 select p.product_id , p.product_name , sum(oi.final_price) as revenue ,
 rank() over (order by sum(oi.final_price) desc) as ranks
 from products p 
 join order_items oi on 
 p.product_id = oi.product_id 
 join orders o on 
 o.order_id = oi.order_id 
 where o.order_status in('Shipped','Delivered')
 group by p.product_id,p.product_name;
 
 -- 62.Find top 3 products in each category. 
 
 with cte as ( select p.product_id ,p.product_name,p.category,sum(oi.final_price) as revenue ,
 rank() over (partition by p.category order by sum(oi.final_price) desc) as ranking 
 from products p
join order_items oi on 
 p.product_id = oi.product_id 
 join orders o on 
 o.order_id = oi.order_id 
 where o.order_status in('Shipped','Delivered')
 group by p.product_id,p.product_name,p.category)
 
 select * from cte 
 where ranking <= 3;

-- 63.Find running total of monthly revenue. 

with cte as ( select year(o.order_date) as year_, month(o.order_date) as month_num,monthname(o.order_date) as month_ ,sum(oi.final_price) as total_revenue from orders o
 join order_items oi on 
 o.order_id = oi.order_id 
 where o.order_status in ('Shipped','Delivered')
 group by year_,month_,month(o.order_date)
 order by year_,month(order_date),month_)
 
select year_,month_,total_revenue,sum(total_revenue) over (order by year_,month_num) as running_total from cte;

-- 64. Find month-over-month sales growth. 
with cte as (select year(o.order_date) as year_,
	   month(o.order_date) as month_num,
       monthname(o.order_date) as month_ ,
       sum(oi.final_price) as revenue , 
       lag(sum(oi.final_price)) over(order by year(o.order_date) , month(o.order_date)) as previous
       from orders o
join order_items oi on 
 o.order_id = oi.order_id 
 where o.order_status in ('Shipped','Delivered')
group by year_,month_num,month_)
select year_,month_,revenue,previous , round(((revenue - previous) / previous)*100,2)  as growth from cte;

-- 65. Find customers whose spending is above average. 
with cte as (select c.customer_id , c.customer_name , sum(oi.final_price) as total_spending from customers c 
join orders o on 
c.customer_id = o.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.customer_id , c.customer_name) 
select * from cte 
where total_spending >(select avg(total_spending) from cte); 

-- 66.Find products contributing to 80% revenue (Pareto Analysis). 
with cte as (select  p.product_name , sum(oi.final_price)  as revenue from products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on 
o.order_id = oi.order_id
where o.order_status in ('Shipped','Delivered')
group by p.product_name),
pareto as  ( select product_name , revenue , sum(revenue) over(order by revenue desc) as running_total,
			sum(revenue) over() as total_revenue,
            round((sum(revenue) over(order by revenue desc) /sum(revenue) over())*100,2) as percentage from cte)
select * from pareto
where percentage <= 80;

-- 67.Segment customers into:High Value,Medium Value,Low Value
with cte as (select c.customer_id, c.customer_name , sum(oi.final_price) as spending from customers c 
join orders o on 
o.customer_id = c.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.customer_id,c.customer_name
order by spending desc)
select customer_id , customer_name , spending ,
          case 
           when spending <= 150000 then 'Low Value'
           when spending <= 250000 then 'Medium value'
           when spending > 250000 then 'High value'
           end as segmentation
           from cte;
           
-- 68.Find customer lifetime value (CLV). 
select c.customer_id,c.customer_name , sum(oi.final_price) as spending from customers c 
join orders o on 
o.customer_id = c.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.customer_id,c.customer_name
order by spending desc;

-- 69.Find inactive customers. 
select c.customer_id ,c.customer_name from customers c 
left join orders o on 
c.customer_id = o.customer_id 
where order_id is null ;

-- 70.Find churn-risk customers.

with cte as (select c.customer_id,c.customer_name , max(o.order_date) as last_order_date from customers c 
join orders o on 
c.customer_id = o.customer_id 
group by c.customer_id ,c.customer_name)
select * from cte 
where last_order_date < current_date() - interval 6 month;


             -- 🧠 Real-World Business Case Studies
             
-- 71.Which products should the company restock urgently 
select p.product_id, p.product_name , p.stock_quantity ,sum(oi.quantity) as sold ,sum(oi.final_price) as revenue from products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered') 
group by p.product_id, p.product_name ,p.stock_quantity 
order by p.stock_quantity asc,sold desc,revenue desc;


-- 72.Which products should be discontinued due to low sales? 
select p.product_id, p.product_name , p.stock_quantity ,sum(oi.quantity) as sold ,sum(oi.final_price) as revenue from products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered') 
group by p.product_id, p.product_name ,p.stock_quantity 
order by p.stock_quantity desc,sold asc,revenue asc;

-- 73.Which states need marketing investment? 
select c.state , count(distinct c.customer_id) as customers , count(distinct o.order_id) as orders , sum(oi.final_price) as sales from customers c
join orders o on 
c.customer_id = o.customer_id
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.state
order by customers asc , orders asc, sales asc;

-- 74.Are discounts increasing or reducing profits? 
 select case 
            when oi.discount_percent <=10 then 'Low Discount'
			when oi.discount_percent <=20 then 'Medium Discount'
			when oi.discount_percent >20 then 'High Discount'
            end as discount_category,
            sum(oi.final_price - (p.cost_price*oi.quantity)) as profit 
            from products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by discount_category
order by profit desc;

-- 75.Which customer segment generates maximum revenue?
with cte as (select c.customer_id, c.customer_name , sum(oi.final_price) as spending from customers c 
join orders o on 
o.customer_id = c.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.customer_id,c.customer_name
order by spending desc),
segmentation as (select customer_id , customer_name , spending ,
          case 
           when spending <= 150000 then 'Low Value'
           when spending <= 250000 then 'Medium value'
           when spending > 250000 then 'High value'
           end as segmentation
           from cte)
select segmentation , sum(spending) as total_spending from segmentation 
group by segmentation
order by total_spending desc;

-- 76.Which categories are growing fastest? 
with cte as (select p.category, year(o.order_date) as year_, sum(oi.final_price) as current_year from orders o 
join order_items oi on 
o.order_id = oi.order_id 
join products p on 
p.product_id = oi.product_id 
where o.order_status in ('Shipped','Delivered')
group by p.category,year_
order by category),
previous as ( select category ,year_,current_year ,lag(current_year) over(PARTITION BY category order by year_) as previous_year from cte)

select category ,year_,current_year,previous_year, round(((current_year - previous_year) / previous_year)*100,2) as growth from previous
order by growth desc;

-- 77.Which brands perform best during peak sales periods?
with peak_months as (select year(o.order_date) as year_,MONTH(o.order_date) AS month_num,monthname(o.order_date) as month_,sum(oi.final_price) as total_sales from products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by YEAR(o.order_date),
        MONTH(o.order_date),
        MONTHNAME(o.order_date)
),
peak_rank as (select year_,month_num,month_,total_sales,
              rank() over(order by total_sales desc) as peak_rank from peak_months),
brand_sales as ( select p.brand , year(o.order_date) as year_,MONTH(o.order_date) AS month_num,monthname(o.order_date) as month_,sum(oi.final_price) as total_sales from products p
join order_items oi on 
p.product_id = oi.product_id 
join orders o on 
o.order_id = oi.order_id 
join peak_rank pr on
year(o.order_date) =pr.year_ and month(o.order_date) = pr.month_num
where o.order_status in ('Shipped','Delivered') and peak_rank <= 3
group by p.brand ,year_,month_num,month_)

select b.brand ,b.year_,b.month_,b.total_sales,
rank() over(partition by b.year_,b.month_num order by b.total_sales desc) as brank_rank 
from brand_sales b ;

-- 78.How can the company reduce cancelled orders? 
 -- payment wise
 select payment_method,count(*) from orders
 where order_status = 'Cancelled'
 group by payment_method;
 
 -- product wise
 select p.product_name , count(*) as cancelletion_count from orders o 
 join order_items oi on 
 o.order_id = oi.order_id 
 join products p on 
 p.product_id = oi.product_id 
 where o.order_status = 'Cancelled'
 group by p.product_name 
 order by cancelletion_count desc
 limit 10;
 
 -- category wise
  select p.category , count(*) as cancelletion_count from orders o 
 join order_items oi on 
 o.order_id = oi.order_id 
 join products p on 
 p.product_id = oi.product_id 
 where o.order_status = 'Cancelled'
 group by p.category
 order by cancelletion_count desc
 limit 10;
 
 -- state wise 
 select c.state , count(*) as cancelletion_count from orders o 
join customers c on 
c.customer_id = o.customer_id
 where o.order_status = 'Cancelled'
 group by c.state
 order by cancelletion_count desc
 limit 10;
 
-- 79.Which payment methods lead to higher order values? 
select o.payment_method , sum(oi.final_price) as revenue from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by o.payment_method 
order by revenue desc;

select o.payment_method , avg(oi.final_price) as revenue from orders o 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by o.payment_method 
order by revenue desc;

-- 80.Which customers are likely VIP customers? 
with cte as (select c.customer_id, c.customer_name , sum(oi.final_price) as spending from customers c 
join orders o on 
o.customer_id = c.customer_id 
join order_items oi on 
o.order_id = oi.order_id 
where o.order_status in ('Shipped','Delivered')
group by c.customer_id,c.customer_name
order by spending desc),
segmentation as (select customer_id , customer_name , spending ,
          case 
           when spending <= 150000 then 'Low Value'
           when spending <= 250000 then 'Medium value'
           when spending > 250000 then 'High value'
           end as segmentation
           from cte)
select customer_name ,spending from segmentation 
where segmentation = 'High value';




