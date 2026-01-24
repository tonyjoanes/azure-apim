using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using VersionedAPI.Models;

namespace VersionedAPI.Controllers.V1;

/// <summary>
/// Products API - Version 1
/// </summary>
[ApiController]
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]
public class ProductsController : ControllerBase
{
    private static readonly List<ProductV1> _products = new()
    {
        new ProductV1 { Id = 1, Name = "Laptop", Price = 999.99m },
        new ProductV1 { Id = 2, Name = "Mouse", Price = 29.99m },
        new ProductV1 { Id = 3, Name = "Keyboard", Price = 79.99m }
    };

    private readonly ILogger<ProductsController> _logger;

    public ProductsController(ILogger<ProductsController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get all products (v1)
    /// </summary>
    /// <returns>List of products</returns>
    /// <response code="200">Returns list of products</response>
    [HttpGet]
    [MapToApiVersion("1.0")]
    [ProducesResponseType(typeof(IEnumerable<ProductV1>), StatusCodes.Status200OK)]
    public ActionResult<IEnumerable<ProductV1>> GetAll()
    {
        _logger.LogInformation("V1: Getting all products");
        return Ok(_products);
    }

    /// <summary>
    /// Get product by ID (v1)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <returns>Product details</returns>
    /// <response code="200">Returns the product</response>
    /// <response code="404">Product not found</response>
    [HttpGet("{id}")]
    [MapToApiVersion("1.0")]
    [ProducesResponseType(typeof(ProductV1), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<ProductV1> GetById(int id)
    {
        _logger.LogInformation("V1: Getting product {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);
        if (product == null)
        {
            return NotFound(new { message = $"Product {id} not found in v1" });
        }

        return Ok(product);
    }

    /// <summary>
    /// Create new product (v1)
    /// </summary>
    /// <param name="product">Product to create</param>
    /// <returns>Created product</returns>
    /// <response code="201">Product created</response>
    [HttpPost]
    [MapToApiVersion("1.0")]
    [ProducesResponseType(typeof(ProductV1), StatusCodes.Status201Created)]
    public ActionResult<ProductV1> Create([FromBody] ProductV1 product)
    {
        _logger.LogInformation("V1: Creating product {ProductName}", product.Name);

        product.Id = _products.Max(p => p.Id) + 1;
        _products.Add(product);

        return CreatedAtAction(nameof(GetById), new { id = product.Id, version = "1.0" }, product);
    }

    /// <summary>
    /// Update product (v1)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <param name="product">Updated product</param>
    /// <returns>Updated product</returns>
    /// <response code="200">Product updated</response>
    /// <response code="404">Product not found</response>
    [HttpPut("{id}")]
    [MapToApiVersion("1.0")]
    [ProducesResponseType(typeof(ProductV1), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<ProductV1> Update(int id, [FromBody] ProductV1 product)
    {
        _logger.LogInformation("V1: Updating product {ProductId}", id);

        var existing = _products.FirstOrDefault(p => p.Id == id);
        if (existing == null)
        {
            return NotFound(new { message = $"Product {id} not found in v1" });
        }

        existing.Name = product.Name;
        existing.Price = product.Price;

        return Ok(existing);
    }

    /// <summary>
    /// Delete product (v1)
    /// </summary>
    /// <param name="id">Product ID</param>
    /// <returns>No content</returns>
    /// <response code="204">Product deleted</response>
    /// <response code="404">Product not found</response>
    [HttpDelete("{id}")]
    [MapToApiVersion("1.0")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult Delete(int id)
    {
        _logger.LogInformation("V1: Deleting product {ProductId}", id);

        var product = _products.FirstOrDefault(p => p.Id == id);
        if (product == null)
        {
            return NotFound(new { message = $"Product {id} not found in v1" });
        }

        _products.Remove(product);
        return NoContent();
    }
}
