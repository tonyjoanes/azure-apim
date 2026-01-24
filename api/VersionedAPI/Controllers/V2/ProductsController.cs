using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using VersionedAPI.Models;

namespace VersionedAPI.Controllers.V2;

/// <summary>
/// Products API - Version 2 (Enhanced)
/// </summary>
[ApiController]
[ApiVersion("2.0")]
[Route("v{version:apiVersion}/products")]
public class ProductsController : ControllerBase
{
    private static readonly List<ProductV2> _products = new()
    {
        new ProductV2
        {
            Id = 1,
            Name = "Laptop",
            Description = "High-performance laptop",
            Price = 999.99m,
            Category = "Electronics",
            Stock = 50,
            ImageUrl = "https://example.com/laptop.jpg"
        },
        new ProductV2
        {
            Id = 2,
            Name = "Mouse",
            Description = "Wireless gaming mouse",
            Price = 29.99m,
            Category = "Accessories",
            Stock = 200,
            ImageUrl = "https://example.com/mouse.jpg"
        },
        new ProductV2
        {
            Id = 3,
            Name = "Keyboard",
            Description = "Mechanical RGB keyboard",
            Price = 79.99m,
            Category = "Accessories",
            Stock = 150,
            ImageUrl = "https://example.com/keyboard.jpg"
        }
    };

    private readonly ILogger<ProductsController> _logger;

    public ProductsController(ILogger<ProductsController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get all products (v2 - enhanced with filtering)
    /// </summary>
    /// <param name="category">Filter by category</param>
    /// <param name="minPrice">Minimum price</param>
    /// <param name="maxPrice">Maximum price</param>
    /// <param name="inStock">Only show in-stock items</param>
    /// <returns>List of products</returns>
    /// <response code="200">Returns list of products</response>
    [HttpGet]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(IEnumerable<ProductV2>), StatusCodes.Status200OK)]
    public ActionResult<IEnumerable<ProductV2>> GetAll(
        [FromQuery] string? category = null,
        [FromQuery] decimal? minPrice = null,
        [FromQuery] decimal? maxPrice = null,
        [FromQuery] bool? inStock = null)
    {
        _logger.LogInformation("V2: Getting all products with filters");

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

        if (inStock.HasValue && inStock.Value)
        {
            query = query.Where(p => p.Stock > 0);
        }

        return Ok(query.ToList());
    }

    /// <summary>
    /// Get product by ID (v2 - enhanced response)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <returns>Product details with full information</returns>
    /// <response code="200">Returns the product</response>
    /// <response code="404">Product not found</response>
    [HttpGet("{id}")]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(ProductV2), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<ProductV2> GetById(int id)
    {
        _logger.LogInformation("V2: Getting product {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);
        if (product == null)
        {
            return NotFound(new
            {
                error = "NotFound",
                message = $"Product {id} not found in v2",
                timestamp = DateTime.UtcNow
            });
        }

        return Ok(product);
    }

    /// <summary>
    /// Search products by name (NEW in v2)
    /// </summary>
    /// <param name="query">Search query</param>
    /// <returns>Matching products</returns>
    /// <response code="200">Returns matching products</response>
    [HttpGet("search")]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(IEnumerable<ProductV2>), StatusCodes.Status200OK)]
    public ActionResult<IEnumerable<ProductV2>> Search([FromQuery] string query)
    {
        _logger.LogInformation("V2: Searching products with query: {Query}", query);

        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(_products);
        }

        var results = _products.Where(p =>
            p.Name.Contains(query, StringComparison.OrdinalIgnoreCase) ||
            p.Description.Contains(query, StringComparison.OrdinalIgnoreCase)
        ).ToList();

        return Ok(results);
    }

    /// <summary>
    /// Get products by category (NEW in v2)
    /// </summary>
    /// <param name="category">Product category</param>
    /// <returns>Products in the category</returns>
    /// <response code="200">Returns products in category</response>
    [HttpGet("category/{category}")]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(IEnumerable<ProductV2>), StatusCodes.Status200OK)]
    public ActionResult<IEnumerable<ProductV2>> GetByCategory(string category)
    {
        _logger.LogInformation("V2: Getting products in category: {Category}", category);

        var products = _products
            .Where(p => p.Category.Equals(category, StringComparison.OrdinalIgnoreCase))
            .ToList();

        return Ok(products);
    }

    /// <summary>
    /// Create new product (v2 - requires full details)
    /// </summary>
    /// <param name="product">Product to create</param>
    /// <returns>Created product</returns>
    /// <response code="201">Product created</response>
    /// <response code="400">Invalid product data</response>
    [HttpPost]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(ProductV2), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<ProductV2> Create([FromBody] ProductV2 product)
    {
        _logger.LogInformation("V2: Creating product {ProductName}", product.Name);

        // V2 validation - requires category
        if (string.IsNullOrEmpty(product.Category))
        {
            return BadRequest(new { message = "Category is required in v2" });
        }

        product.Id = _products.Max(p => p.Id) + 1;
        _products.Add(product);

        return CreatedAtAction(nameof(GetById), new { id = product.Id, version = "2.0" }, product);
    }

    /// <summary>
    /// Update product (v2 - full update)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <param name="product">Updated product</param>
    /// <returns>Updated product</returns>
    /// <response code="200">Product updated</response>
    /// <response code="404">Product not found</response>
    [HttpPut("{id}")]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(ProductV2), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<ProductV2> Update(int id, [FromBody] ProductV2 product)
    {
        _logger.LogInformation("V2: Updating product {ProductId}", id);

        var existing = _products.FirstOrDefault(p => p.Id == id);
        if (existing == null)
        {
            return NotFound(new { message = $"Product {id} not found in v2" });
        }

        existing.Name = product.Name;
        existing.Description = product.Description;
        existing.Price = product.Price;
        existing.Category = product.Category;
        existing.Stock = product.Stock;
        existing.ImageUrl = product.ImageUrl;

        return Ok(existing);
    }

    /// <summary>
    /// Update stock quantity (NEW in v2)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <param name="quantity">New stock quantity</param>
    /// <returns>Updated product</returns>
    /// <response code="200">Stock updated</response>
    /// <response code="404">Product not found</response>
    [HttpPatch("{id}/stock")]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(typeof(ProductV2), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<ProductV2> UpdateStock(int id, [FromQuery] int quantity)
    {
        _logger.LogInformation("V2: Updating stock for product {ProductId} to {Quantity}", id, quantity);

        var product = _products.FirstOrDefault(p => p.Id == id);
        if (product == null)
        {
            return NotFound(new { message = $"Product {id} not found in v2" });
        }

        product.Stock = quantity;
        return Ok(product);
    }

    /// <summary>
    /// Delete product (v2)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <returns>No content</returns>
    /// <response code="204">Product deleted</response>
    /// <response code="404">Product not found</response>
    [HttpDelete("{id}")]
    [MapToApiVersion("2.0")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult Delete(int id)
    {
        _logger.LogInformation("V2: Deleting product {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);
        if (product == null)
        {
            return NotFound(new { message = $"Product {id} not found in v2" });
        }

        _products.Remove(product);
        return NoContent();
    }
}
