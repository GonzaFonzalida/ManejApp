export type CarDTO = {
  brand: string;
  model: string;
  instructorId: number;
  year: number;
  licensePlate: string;
  transmission: "MANUAL" | "AUTOMATIC";
};

export type CarWithId = CarDTO & { id: number };
