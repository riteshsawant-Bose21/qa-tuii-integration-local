/* --- Files --- */
export interface FileMeta {
  id: string;
  filename: string;
  size: number;
  uploaded_at: string;
  mime_type: string;
}

export interface AxiosResponse<T> {
  data: T;
  status: string;
  message: string;
}
