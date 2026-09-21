import { Injectable, NotFoundException } from '@nestjs/common';

export interface ShipmentOrder {
  id: string;
  orderId: string;
  parentId: string;
  kitSku: string;
  kitName: string;
  carrier: 'VNPost' | 'GHN' | 'GHTK';
  trackingNumber: string;
  status: 'ordered' | 'packed' | 'shipping' | 'delivered';
  shippingAddress: string;
  recipientName: string;
  recipientPhone: string;
  estimatedDeliveryDate: string;
}

@Injectable()
export class FulfillmentService {
  private readonly shipments: Map<string, ShipmentOrder> = new Map([
    [
      'del_001',
      {
        id: 'del_001',
        orderId: 'ORD-2026-8921',
        parentId: 'parent_1',
        kitSku: 'KIT-BASIC-01',
        kitName: 'Hộp Học Cụ Cọ Vẽ & Bảng Màu Pha Nước ArtKids (4-6T)',
        carrier: 'VNPost',
        trackingNumber: 'VNPOST-884920194',
        status: 'shipping',
        shippingAddress: '123 Đường Sáng Tạo, Quận 1, TP. Hồ Chí Minh',
        recipientName: 'Nguyễn Văn Phụ Huynh',
        recipientPhone: '0901234567',
        estimatedDeliveryDate: '18/09/2026',
      },
    ],
  ]);

  getByParentId(parentId: string): ShipmentOrder[] {
    return Array.from(this.shipments.values()).filter(
      (s) => s.parentId === parentId,
    );
  }

  getByTrackingNumber(trackingNumber: string): ShipmentOrder {
    const shipment = Array.from(this.shipments.values()).find(
      (s) => s.trackingNumber === trackingNumber,
    );
    if (!shipment) {
      throw new NotFoundException(`Không tìm thấy vận đơn: ${trackingNumber}`);
    }
    return shipment;
  }

  updateStatusFromWebhook(
    trackingNumber: string,
    status: ShipmentOrder['status'],
  ): ShipmentOrder {
    const shipment = this.getByTrackingNumber(trackingNumber);
    shipment.status = status;
    return shipment;
  }
}
