namespace VersionedAPI.Models;

/// <summary>
/// Product model - Version 1
/// </summary>
public class ProductV1
{
    /// <summary>
    /// Product ID
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Product name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Product price
    /// </summary>
    public decimal Price { get; set; }
}

/// <summary>
/// Product model - Version 2 (Enhanced)
/// </summary>
public class ProductV2
{
    /// <summary>
    /// Product ID
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Product name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Product description - NEW in v2
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Product price
    /// </summary>
    public decimal Price { get; set; }

    /// <summary>
    /// Product category - NEW in v2
    /// </summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// Stock availability - NEW in v2
    /// </summary>
    public int Stock { get; set; }

    /// <summary>
    /// Product image URL - NEW in v2
    /// </summary>
    public string? ImageUrl { get; set; }
}
