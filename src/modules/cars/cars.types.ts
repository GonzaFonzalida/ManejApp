export type CarDTO = {
  brand: string;
  model: string;
  instructorId: number;
  year: number;
  licensePlate: string;
  transmission: "MANUAL" | "AUTOMATIC";
  isActive?: boolean;
};

export type CarWithId = CarDTO & { 
  id: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
};
