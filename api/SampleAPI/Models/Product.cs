namespace SampleAPI.Models;

/// <summary>
/// Represents a product in the catalog
/// </summary>
public class Product
{
    /// <summary>
    /// Unique identifier for the product
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Product name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Product description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Product price in USD
    /// </summary>
    public decimal Price { get; set; }

    /// <summary>
    /// Product category
    /// </summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// Available stock quantity
    /// </summary>
    public int Stock { get; set; }

    /// <summary>
    /// Date when the product was created
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Whether the product is currently available
    /// </summary>
    public bool IsAvailable { get; set; } = true;
}
