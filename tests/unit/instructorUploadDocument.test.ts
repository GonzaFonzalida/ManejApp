import fs from "fs";
import InstructorService from "../../src/modules/instructors/instructor.services";
import { InstructorRepository } from "../../src/modules/instructors/repositories/InstructorRepository";

describe("InstructorService.uploadDocumentBase64", () => {
  it("updates document path and resets review to pending (upsertDocumentReviewPending)", async () => {
    jest.spyOn(fs, "existsSync").mockReturnValue(true);
    jest.spyOn(fs, "mkdirSync").mockImplementation(() => undefined);
    jest.spyOn(fs, "writeFileSync").mockImplementation(() => undefined);

    const updateDocument = jest.fn().mockResolvedValue({});
    const upsertDocumentReviewPending = jest.fn().mockResolvedValue(undefined);

    const repo = {
      updateDocument,
      upsertDocumentReviewPending,
    } as unknown as InstructorRepository;

    const svc = new InstructorService(repo, {} as never, {} as never);

    await svc.uploadDocumentBase64(7, "licenciaImg", Buffer.from("fake").toString("base64"));

    expect(updateDocument).toHaveBeenCalledWith(7, "licenciaImg", expect.stringMatching(/licenciaImg-7-/));
    expect(upsertDocumentReviewPending).toHaveBeenCalledWith(7, "licenciaImg");

    jest.restoreAllMocks();
  });
});
