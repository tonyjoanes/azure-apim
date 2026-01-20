using Microsoft.AspNetCore.Mvc;
using SampleAPI.Models;

namespace SampleAPI.Controllers;

/// <summary>
/// Products API endpoints
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ProductsController : ControllerBase
{
    private static readonly List<Product> _products = new()
    {
        new Product { Id = 1, Name = "Laptop", Description = "High-performance laptop", Price = 1299.99m, Category = "Electronics", Stock = 50 },
        new Product { Id = 2, Name = "Mouse", Description = "Wireless mouse", Price = 29.99m, Category = "Electronics", Stock = 200 },
        new Product { Id = 3, Name = "Keyboard", Description = "Mechanical keyboard", Price = 89.99m, Category = "Electronics", Stock = 150 },
        new Product { Id = 4, Name = "Monitor", Description = "27-inch 4K monitor", Price = 399.99m, Category = "Electronics", Stock = 75 },
        new Product { Id = 5, Name = "Headphones", Description = "Noise-cancelling headphones", Price = 249.99m, Category = "Electronics", Stock = 100 }
    };

    private readonly ILogger<ProductsController> _logger;

    public ProductsController(ILogger<ProductsController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get all products
    /// </summary>
    /// <param name="category">Optional category filter</param>
    /// <param name="minPrice">Minimum price filter</param>
    /// <param name="maxPrice">Maximum price filter</param>
    /// <returns>List of products</returns>
    /// <response code="200">Returns the list of products</response>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<Product>), StatusCodes.Status200OK)]
    public ActionResult<IEnumerable<Product>> GetAll(
        [FromQuery] string? category = null,
        [FromQuery] decimal? minPrice = null,
        [FromQuery] decimal? maxPrice = null)
    {
        _logger.LogInformation("Getting all products with filters - Category: {Category}, MinPrice: {MinPrice}, MaxPrice: {MaxPrice}",
            category, minPrice, maxPrice);

        var query = _products.AsEnumerable();

        if (!string.IsNullOrEmpty(category))
        {
            query = query.Where(p => p.Category.Equals(category, StringComparison.OrdinalIgnoreCase));
        }

        if (minPrice.HasValue)
        {
            query = query.Where(p => p.Price >= minPrice.Value);
        }

        if (maxPrice.HasValue)
        {
            query = query.Where(p => p.Price <= maxPrice.Value);
        }

        return Ok(query.ToList());
    }

    /// <summary>
    /// Get a specific product by ID
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <returns>Product details</returns>
    /// <response code="200">Returns the product</response>
    /// <response code="404">Product not found</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(Product), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<Product> GetById(int id)
    {
        _logger.LogInformation("Getting product with ID: {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);

        if (product == null)
        {
            _logger.LogWarning("Product with ID {ProductId} not found", id);
            return NotFound(new { message = $"Product with ID {id} not found" });
        }

        return Ok(product);
    }

    /// <summary>
    /// Create a new product
    /// </summary>
    /// <param name="product">Product details</param>
    /// <returns>Created product</returns>
    /// <response code="201">Product created successfully</response>
    /// <response code="400">Invalid request</response>
    [HttpPost]
    [ProducesResponseType(typeof(Product), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<Product> Create([FromBody] Product product)
    {
        _logger.LogInformation("Creating new product: {ProductName}", product.Name);

        if (string.IsNullOrEmpty(product.Name))
        {
            return BadRequest(new { message = "Product name is required" });
        }

        product.Id = _products.Max(p => p.Id) + 1;
        product.CreatedAt = DateTime.UtcNow;
        _products.Add(product);

        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }

    /// <summary>
    /// Update an existing product
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <param name="updatedProduct">Updated product details</param>
    /// <returns>Updated product</returns>
    /// <response code="200">Product updated successfully</response>
    /// <response code="404">Product not found</response>
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(Product), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<Product> Update(int id, [FromBody] Product updatedProduct)
    {
        _logger.LogInformation("Updating product with ID: {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);

        if (product == null)
        {
            _logger.LogWarning("Product with ID {ProductId} not found", id);
            return NotFound(new { message = $"Product with ID {id} not found" });
        }

        product.Name = updatedProduct.Name;
        product.Description = updatedProduct.Description;
        product.Price = updatedProduct.Price;
        product.Category = updatedProduct.Category;
        product.Stock = updatedProduct.Stock;
        product.IsAvailable = updatedProduct.IsAvailable;

        return Ok(product);
    }

    /// <summary>
    /// Delete a product
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <returns>No content</returns>
    /// <response code="204">Product deleted successfully</response>
    /// <response code="404">Product not found</response>
    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult Delete(int id)
    {
        _logger.LogInformation("Deleting product with ID: {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);

        if (product == null)
        {
            _logger.LogWarning("Product with ID {ProductId} not found", id);
            return NotFound(new { message = $"Product with ID {id} not found" });
        }

        _products.Remove(product);
        return NoContent();
    }
}
