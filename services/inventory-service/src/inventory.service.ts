import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';

export interface InventoryItem {
  sku: string;
  name: string;
  quantityAvailable: number;
  quantityReserved: number;
  reorderThreshold: number;
  unitCostVnd: number;
}

@Injectable()
export class InventoryService {
  private readonly stock: Map<string, InventoryItem> = new Map([
    [
      'KIT-BASIC-01',
      {
        sku: 'KIT-BASIC-01',
        name: 'Hộp Học Cụ Cọ Vẽ & Bảng Màu Pha Nước ArtKids (4-6T)',
        quantityAvailable: 450,
        quantityReserved: 35,
        reorderThreshold: 50,
        unitCostVnd: 120000,
      },
    ],
    [
      'KIT-CLAY-02',
      {
        sku: 'KIT-CLAY-02',
        name: 'Bộ Dựng Hình Khối & Đất Nặn Tạo Hình 3D Cao Cấp (7-12T)',
        quantityAvailable: 320,
        quantityReserved: 20,
        reorderThreshold: 40,
        unitCostVnd: 160000,
      },
    ],
  ]);

  getAllStock(): InventoryItem[] {
    return Array.from(this.stock.values());
  }

  getBySku(sku: string): InventoryItem {
    const item = this.stock.get(sku);
    if (!item) {
      throw new NotFoundException(`SKU ${sku} không tồn tại trong kho`);
    }
    return item;
  }

  reserveStock(sku: string, quantity: number): InventoryItem {
    const item = this.getBySku(sku);
    if (item.quantityAvailable < quantity) {
      throw new BadRequestException(`Không đủ số lượng tồn kho cho SKU ${sku}`);
    }
    item.quantityAvailable -= quantity;
    item.quantityReserved += quantity;
    return item;
  }

  releaseStock(sku: string, quantity: number): InventoryItem {
    const item = this.getBySku(sku);
    item.quantityReserved = Math.max(0, item.quantityReserved - quantity);
    item.quantityAvailable += quantity;
    return item;
  }
}
